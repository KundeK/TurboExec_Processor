module arbiter_2
(
    input   logic           clk,
    input   logic           rst,
    
    // icache interface
    input   logic   [31:0]  icache_addr,
    input   logic           icache_read,
    input   logic           icache_write,
    output  logic   [255:0] icache_rdata,
    input   logic   [255:0] icache_wdata,
    output  logic           icache_resp,
    
    // dcache interface
    input   logic   [31:0]  dcache_addr,
    input   logic           dcache_read,
    input   logic           dcache_write,
    output  logic   [255:0] dcache_rdata,
    input   logic   [255:0] dcache_wdata,
    output  logic           dcache_resp,
    
    // cacheline adapter interface
    output  logic   [31:0]  adapter_addr,
    output  logic           adapter_read,
    output  logic           adapter_write,
    input   logic   [255:0] adapter_rdata,
    output  logic   [255:0] adapter_wdata,
    input   logic           adapter_resp
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        SERVING_ICACHE = 2'b01,
        SERVING_DCACHE = 2'b10
    } arbiter_state_t;
    
    arbiter_state_t state, next_state;
    
    // Saved request signals
    logic saved_icache_request, saved_dcache_request;
    
    // Track the adapter response
    logic adapter_resp_captured;
    logic [255:0] adapter_rdata_captured;
    
    // FSM state register
    always_ff @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Register to capture adapter response
    always_ff @(posedge clk) begin
        if (rst) begin
            adapter_resp_captured <= 1'b0;
            adapter_rdata_captured <= '0;
        end
        else if (adapter_resp) begin
            adapter_resp_captured <= 1'b1;
            adapter_rdata_captured <= adapter_rdata;
        end
        else if ((state == SERVING_ICACHE && icache_resp) || 
                 (state == SERVING_DCACHE && dcache_resp)) begin
            adapter_resp_captured <= 1'b0;
        end
    end
    
    // Pending request tracking
    always_ff @(posedge clk) begin
        if (rst) begin
            saved_icache_request <= 1'b0;
            saved_dcache_request <= 1'b0;
        end
        else begin
            // Save icache req if busy with dcache
            if ((icache_read || icache_write) && (state == SERVING_DCACHE) && !saved_icache_request)
                saved_icache_request <= 1'b1;
            else if (state == SERVING_ICACHE)
                saved_icache_request <= 1'b0;
                
            // Save dcache req if busy with icache
            if ((dcache_read || dcache_write) && (state == SERVING_ICACHE) && !saved_dcache_request)
                saved_dcache_request <= 1'b1;
            else if (state == SERVING_DCACHE)
                saved_dcache_request <= 1'b0;
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            // Prioritize icache over dcache
            IDLE: begin
                if (icache_read || icache_write)
                    next_state = SERVING_ICACHE;
                else if (dcache_read || dcache_write)
                    next_state = SERVING_DCACHE;
            end
            
            SERVING_ICACHE: begin
                if (adapter_resp) begin
                    // Finished icache
                    if (saved_dcache_request || (dcache_read || dcache_write))
                        next_state = SERVING_DCACHE;
                    // else if (icache_read || icache_write)
                    //     next_state = SERVING_ICACHE;  // another icache req
                    else
                        next_state = IDLE;
                end
            end
            
            SERVING_DCACHE: begin
                if (adapter_resp) begin
                    // Finished dcache
                    if (saved_icache_request || (icache_read || icache_write))
                        next_state = SERVING_ICACHE;
                    // else if (dcache_read || dcache_write)
                    //     next_state = SERVING_DCACHE;  // another dcache req
                    else
                        next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Output logic
    always_comb begin
        // Default
        icache_resp = 1'b0;
        dcache_resp = 1'b0;
        icache_rdata = 256'b0;
        dcache_rdata = 256'b0;
        
        adapter_addr = 32'b0;
        adapter_read = 1'b0;
        adapter_write = 1'b0;
        adapter_wdata = 256'b0;
        
        case (state)
            IDLE: begin
                // no resp just pass through req
                if (icache_read || icache_write) begin
                    adapter_addr = icache_addr;
                    adapter_read = icache_read;
                    adapter_write = icache_write;
                    adapter_wdata = icache_wdata;
                end
                else if (dcache_read || dcache_write) begin
                    adapter_addr = dcache_addr;
                    adapter_read = dcache_read;
                    adapter_write = dcache_write;
                    adapter_wdata = dcache_wdata;
                end
            end
            
            SERVING_ICACHE: begin
                // Connect icache to adapter
                adapter_addr = icache_addr;
                adapter_read = icache_read;
                adapter_write = icache_write;
                adapter_wdata = icache_wdata;
                
                // if (adapter_resp || adapter_resp_captured) begin
                //     icache_resp = 1'b1;
                //     icache_rdata = adapter_resp ? adapter_rdata : adapter_rdata_captured;
                // end
                if (adapter_resp) begin
                    icache_resp = 1'b1;
                    icache_rdata = adapter_resp ? adapter_rdata : adapter_rdata_captured;
                end
            end
            
            SERVING_DCACHE: begin
                // Connect dcache to adapter
                adapter_addr = dcache_addr;
                adapter_read = dcache_read;
                adapter_write = dcache_write;
                adapter_wdata = dcache_wdata;
                
                // if (adapter_resp || adapter_resp_captured) begin
                //     dcache_resp = 1'b1;
                //     dcache_rdata = adapter_resp ? adapter_rdata : adapter_rdata_captured;
                // end
                if (adapter_resp) begin
                    dcache_resp = 1'b1;
                    dcache_rdata = adapter_resp ? adapter_rdata : adapter_rdata_captured;
                end
            end
        endcase
    end

endmodule : arbiter_2