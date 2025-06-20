module cacheline_adapter
(
    // Clock and reset
    input   logic               clk,
    input   logic               rst,
    
    // Cache-side signals (dfp - from/to cache)
    input   logic   [31:0]      dfp_addr,      
    input   logic               dfp_read,   
    input   logic               dfp_write,
    input   logic   [255:0]     dfp_wdata,   
    output  logic   [255:0]     dfp_rdata, 
    output  logic               dfp_resp,   
    
    // Memory-side signals (bmem - to/from memory)
    output  logic   [31:0]      bmem_addr,  
    output  logic               bmem_read, 
    output  logic               bmem_write,   
    output  logic   [63:0]      bmem_wdata,
    input   logic   [31:0]      bmem_raddr,   
    input   logic   [63:0]      bmem_rdata,  
    input   logic               bmem_rvalid,
    input   logic               bmem_ready
);

    // States
    enum integer unsigned {
        IDLE,
        READ_BURST1,
        READ_BURST2,
        READ_BURST3,
        READ_BURST4,
        READ_BURST5,
        WRITE_BURST1,
        WRITE_BURST2,
        WRITE_BURST3,
        WRITE_BURST4
    } state, next_state;
    
    logic [255:0] data_buffer;   
    logic [1:0]   read_burst_count;  
    logic         read_in_progress;
    
    // FSM logic
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            data_buffer <= '0;
            read_burst_count <= '0;
            read_in_progress <= 1'b0;
        end else begin
            state <= next_state;
            
            // Capture data when valid
            if (bmem_rvalid && read_in_progress && (bmem_raddr[0] || ~bmem_raddr[0])) begin
                case (read_burst_count)
                    2'd0: data_buffer[63:0] <= bmem_rdata;
                    2'd1: data_buffer[127:64] <= bmem_rdata;
                    2'd2: data_buffer[191:128] <= bmem_rdata;
                    2'd3: data_buffer[255:192] <= bmem_rdata;
                endcase
                
                read_burst_count <= read_burst_count + 1'b1;
            end
            
            if (state == IDLE && bmem_read) begin // Set read flag
                read_in_progress <= 1'b1;
                read_burst_count <= '0;
            end
            if (state == READ_BURST4) begin  // Clear read flag
                read_in_progress <= 1'b0;
            end
        end
    end
    
    // State transitions
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (dfp_read && bmem_ready) begin
                    next_state = READ_BURST1;
                end else if (dfp_write && bmem_ready) begin
                    next_state = WRITE_BURST1;
                end
            end
            
            // Read transitions
            READ_BURST1: begin
                if (bmem_rvalid) next_state = READ_BURST2;
            end
            READ_BURST2: begin
                if (bmem_rvalid) next_state = READ_BURST3;
            end
            READ_BURST3: begin
                if (bmem_rvalid) next_state = READ_BURST4;
            end
            READ_BURST4: begin
                if (bmem_rvalid) next_state = READ_BURST5;
            end
            READ_BURST5: begin
                next_state = IDLE;
            end
            
            // Write transitions
            WRITE_BURST1: next_state = WRITE_BURST2;
            WRITE_BURST2: next_state = WRITE_BURST3;
            WRITE_BURST3: next_state = WRITE_BURST4;
            WRITE_BURST4: next_state = IDLE;
            
            default: next_state = IDLE;
        endcase
    end
    
    // Outputoutput
    always_comb begin
        bmem_addr = dfp_addr; 
        bmem_read = 1'b0;
        bmem_write = 1'b0;
        bmem_wdata = '0;
        dfp_rdata = '0;
        dfp_resp = 1'b0;
        
        case (state)
            IDLE: begin
                // Respond to new requests
                if (dfp_read && bmem_ready) begin
                    bmem_read = 1'b1;
                end else if (dfp_write && bmem_ready) begin
                    bmem_write = 1'b1;
                    bmem_wdata = dfp_wdata[63:0];  // First burst
                end
            end
            
            // Read bursts
            READ_BURST1, READ_BURST2, READ_BURST3, READ_BURST4: begin
                bmem_read = 1'b0;
            end
            READ_BURST5: begin
                bmem_read = 1'b0;
                dfp_rdata = data_buffer;
                dfp_resp = 1'b1; // Signal completion
            end
    
            // Write bursts
            WRITE_BURST1: begin
                bmem_write = 1'b1;
                bmem_wdata = dfp_wdata[127:64];
            end
            WRITE_BURST2: begin
                bmem_write = 1'b1;
                bmem_wdata = dfp_wdata[191:128];
            end
            WRITE_BURST3: begin
                bmem_write = 1'b1;
                bmem_wdata = dfp_wdata[255:192];
            end
            WRITE_BURST4: begin
                dfp_resp = 1'b1; // Signal completion
            end
        endcase
    end

endmodule : cacheline_adapter