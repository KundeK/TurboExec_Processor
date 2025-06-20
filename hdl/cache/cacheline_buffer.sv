module cacheline_buffer (
    input   logic           clk,
    input   logic           rst,

    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    output  logic   [31:0]  ufp_rdata,
    output  logic           ufp_resp,

    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    // output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    // output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    logic           valid_reg;
    logic           valid_reg_next;

    logic   [255:0] linebuf_data_reg;
    logic   [26:0]  linebuf_tag_reg;

    logic   [255:0] linebuf_data_reg_next;
    logic   [26:0]  linebuf_tag_reg_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            linebuf_data_reg <= 256'h0;
            linebuf_tag_reg <= 27'h0;
            valid_reg <= 1'b0;
        end
        else begin
            linebuf_data_reg <= linebuf_data_reg_next;
            linebuf_tag_reg <= linebuf_tag_reg_next;
            valid_reg <= valid_reg_next;
        end
    end

    always_comb begin
        linebuf_data_reg_next = linebuf_data_reg;
        linebuf_tag_reg_next = linebuf_tag_reg;
        valid_reg_next = valid_reg;

        ufp_rdata = 'x;
        ufp_resp = 1'b0;

        dfp_addr = 'x;
        dfp_read = 1'b0;

        if (ufp_rmask != 4'b0000) begin
            if(ufp_addr[31:5] == linebuf_tag_reg && valid_reg) begin    // hit, same cycle resp
                ufp_resp = 1'b1;
                ufp_rdata = linebuf_data_reg[(ufp_addr[4:2] * 32) +: 32];
            end
            else begin                      // miss, req from dfp (icache)
                dfp_read = 1'b1;
                dfp_addr = ufp_addr;

                if (dfp_resp) begin
                    linebuf_data_reg_next = dfp_rdata;
                    linebuf_tag_reg_next = ufp_addr[31:5];
                    valid_reg_next = 1'b1;
                end
            end
        end
    end

endmodule