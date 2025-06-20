module bit_select_mux (
    input   logic           cache_bit0,
    input   logic           cache_bit1,
    input   logic           cache_bit2,
    input   logic           cache_bit3,

    input   logic   [1:0]   bit_select,

    output  logic           out_bit
);
    // use for valid/dirty compare

    always_comb begin

        unique case (bit_select)
            2'b00: begin
                out_bit = cache_bit0;
            end
            2'b01: begin
                out_bit = cache_bit1;
            end
            2'b10: begin
                out_bit = cache_bit2;
            end
            2'b11: begin
                out_bit = cache_bit3;
            end
        endcase

        // bit_match = 1'b0;
        // bit_select = 2'b00;

        // if (in_bit == cache_bit0) begin
        //     bit_match = 1'b1;
        //     bit_select = 2'b00;
        // end
        // else if (in_bit == cache_bit1) begin
        //     bit_match = 1'b1;
        //     bit_select = 2'b01;
        // end
        // else if (in_bit == cache_bit2) begin
        //     bit_match = 1'b1;
        //     bit_select = 2'b10;
        // end
        // else if (in_bit == cache_bit3) begin
        //     bit_match = 1'b1;
        //     bit_select = 2'b11;
        // end
    end

endmodule
