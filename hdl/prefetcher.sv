module prefetcher
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    input   logic   [31:0]      ufp_addr,
    input   logic               ufp_read,
    output  logic   [255:0]     ufp_rdata,
    output  logic               ufp_resp,

    output  logic   [31:0]      dfp_addr,
    output  logic               dfp_read,
    input   logic               dfp_resp,
    input   logic   [255:0]     dfp_rdata
);

// if ufp addr does not match prefetch addr, act as pass through, then queue prefetch addr req
// if match, send prefetch data

    logic   [255:0]     prefetch_data;
    logic   [31:0]      prefetch_addr;
    logic               prefetch_valid;
    logic               queue_prefetch;

    logic   [255:0]     prefetch_data_next;
    logic   [31:0]      prefetch_addr_next;
    logic               prefetch_valid_next;
    logic               queue_prefetch_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            prefetch_data <= 256'b0;
            prefetch_addr <= 32'b0;
            prefetch_valid <= 1'b0;
            queue_prefetch <= 1'b0;
        end
        else begin
            prefetch_data <= prefetch_data_next;
            prefetch_addr <= prefetch_addr_next;
            prefetch_valid <= prefetch_valid_next;
            queue_prefetch <= queue_prefetch_next;           
        end
    end

    always_comb begin
        ufp_resp = 1'b0;
        ufp_rdata = 'x;
        dfp_addr = 'x;
        dfp_read = 1'b0;

        prefetch_data_next = prefetch_data;
        prefetch_addr_next = prefetch_addr;
        prefetch_valid_next = prefetch_valid;
        queue_prefetch_next = queue_prefetch;

        if (ufp_read & ufp_addr == prefetch_addr & prefetch_valid) begin
            ufp_rdata = prefetch_data;
            ufp_resp = 1'b1;

            prefetch_addr_next = prefetch_addr + 'd32;
            prefetch_valid_next = 1'b0;
            queue_prefetch_next = 1'b1;
        end
        else begin
            if (~queue_prefetch) begin
                // fetch current cache line
                dfp_addr = ufp_addr;
                dfp_read = ufp_read;

                if (dfp_resp) begin
                    ufp_resp = 1'b1;
                    ufp_rdata = dfp_rdata;        
                    
                    prefetch_addr_next = ufp_addr + 'd32;
                    prefetch_valid_next = 1'b0;
                    queue_prefetch_next = 1'b1;
                end
            end
            else begin
                dfp_addr = prefetch_addr;
                dfp_read = 1'b1;

                if (dfp_resp) begin
                    prefetch_data_next = dfp_rdata;
                    prefetch_valid_next = 1'b1;
                    queue_prefetch_next = 1'b0;
                end
            end
        end
    end

endmodule : prefetcher