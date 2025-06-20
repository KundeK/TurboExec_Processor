module tag_array_compare (
    input   logic   [22:0]      tag,

    input   logic   [22:0]      cache_tag0,
    input   logic   [22:0]      cache_tag1,
    input   logic   [22:0]      cache_tag2,
    input   logic   [22:0]      cache_tag3,

    input   logic               cache_valid_0,
    input   logic               cache_valid_1,
    input   logic               cache_valid_2,
    input   logic               cache_valid_3,

    output  logic   [1:0]       tag_select,
    output  logic               tag_match
);

    always_comb begin
        tag_match = 1'b0;
        tag_select = 2'b00;

        if (tag == cache_tag0 && cache_valid_0) begin
            tag_match = 1'b1;
            tag_select = 2'b00;
        end
        else if (tag == cache_tag1 && cache_valid_1) begin
            tag_match = 1'b1;
            tag_select = 2'b01;
        end
        else if (tag == cache_tag2 && cache_valid_2) begin
            tag_match = 1'b1;
            tag_select = 2'b10;
        end
        else if (tag == cache_tag3 && cache_valid_3) begin
            tag_match = 1'b1;
            tag_select = 2'b11;
        end
    end

endmodule
