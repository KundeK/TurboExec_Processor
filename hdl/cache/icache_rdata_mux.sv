module icache_rdata_mux (
    input   logic       [255:0]     cacheline_0,
    input   logic       [255:0]     cacheline_1,
    input   logic       [255:0]     cacheline_2,
    input   logic       [255:0]     cacheline_3,

    input   logic       [1:0]       line_select,

    // input   logic       [4:0]       offset,
    // input   logic       [3:0]       rmask,

    output  logic       [255:0]      cache_rdata
);

    // logic   [31:0]      bitmask;
    // logic   [31:0]      cache_word;

    // assign bitmask = {{8{rmask[3]}}, {8{rmask[2]}}, {8{rmask[1]}}, {8{rmask[0]}}};

    always_comb begin
        unique case (line_select)
            2'b00: begin
                // cache_word = cacheline_0[(offset[4:2] * 32) +: 32];
                cache_rdata = cacheline_0;
            end
            2'b01: begin
                // cache_word = cacheline_1[(offset[4:2] * 32) +: 32];
                cache_rdata = cacheline_1;
            end
            2'b10: begin
                // cache_word = cacheline_2[(offset[4:2] * 32) +: 32];
                cache_rdata = cacheline_2;
            end
            2'b11: begin
                // cache_word = cacheline_3[(offset[4:2] * 32) +: 32];
                cache_rdata = cacheline_3;
            end
        endcase

        // cache_rdata = cache_word & bitmask;
    end

endmodule
