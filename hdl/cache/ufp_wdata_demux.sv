module ufp_wdata_demux (
    input   logic       [31:0]      wdata,
    input   logic       [3:0]       wmask,
    input   logic       [4:0]       offset,

    input   logic       [1:0]       line_select,

    output  logic       [255:0]     cacheline_0,
    output  logic       [255:0]     cacheline_1,
    output  logic       [255:0]     cacheline_2,
    output  logic       [255:0]     cacheline_3,

    output  logic       [31:0]      cache_wmask_0,
    output  logic       [31:0]      cache_wmask_1,
    output  logic       [31:0]      cache_wmask_2,
    output  logic       [31:0]      cache_wmask_3
);

    logic   [255:0]     cacheline_write;
    logic   [31:0]      word_write;
    logic   [31:0]      bitmask;

    logic   [31:0]      cache_wmask_write;

    assign bitmask = {{8{wmask[3]}}, {8{wmask[2]}}, {8{wmask[1]}}, {8{wmask[0]}}};
    assign word_write = wdata & bitmask;

    always_comb begin
        cacheline_write = '0;
        cacheline_write[(offset[4:2] * 32) +: 32] = word_write;

        cache_wmask_write = '0;
        cache_wmask_write[(offset[4:2] * 4) +: 4] = wmask;

        cacheline_0 = '0;
        cacheline_1 = '0;
        cacheline_2 = '0;
        cacheline_3 = '0;

        cache_wmask_0 = '0;
        cache_wmask_1 = '0;
        cache_wmask_2 = '0;
        cache_wmask_3 = '0;
        // cache_wmask[(offset[4:2] * 4) +: 4] = wmask;

        unique case (line_select)
            2'b00: begin
                cacheline_0 = cacheline_write;
                cache_wmask_0 = cache_wmask_write;
            end
            2'b01: begin
                cacheline_1 = cacheline_write;
                cache_wmask_1 = cache_wmask_write;
            end
            2'b10: begin
                cacheline_2 = cacheline_write;
                cache_wmask_2 = cache_wmask_write;
            end
            2'b11: begin
                cacheline_3 = cacheline_write;
                cache_wmask_3 = cache_wmask_write;
            end
        endcase
    end

endmodule
