module prf #(
    parameter               PHYS_REG_BITS = 6
)(
    input   logic           clk,
    input   logic           rst,
    input   logic           stall,
    input   logic           regf_we, valid_we,
    input   logic           rd_valid,
    input   logic   [31:0]  rd_v,
    input   logic   [PHYS_REG_BITS-1:0]   rs1_s, rs2_s, rd_s, commit_rd_s,
    output  logic   [31:0]  rs1_v, rs2_v,
    output  logic           rs1_valid, rs2_valid,

    input   logic           push, pop, flush,
    output  logic           push_resp, pop_resp,
    output  logic  [PHYS_REG_BITS-1:0]    pop_data, head, tail
);

    localparam                      length = 2**PHYS_REG_BITS;

    // logic   [PHYS_REG_BITS-1:0]     valid;
    // logic   [PHYS_REG_BITS-1:0]     data[32];

    logic   [31:0]                  data[length];
    logic                           valid[length];

    logic   [PHYS_REG_BITS-1:0]     prf_head;
    logic   [PHYS_REG_BITS-1:0]     prf_tail;

    assign head = prf_head;
    assign tail = prf_tail;

    freelist #(
        .PHYS_REG_BITS(PHYS_REG_BITS)
    ) freelist_i (
        .head(prf_head),
        .tail(prf_tail),
        .*
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < length; i++) begin
                valid[i] <= 1'b0;
                data[i] <= 32'b0;
            end
        end
        else begin
            if (regf_we) begin
                data[rd_s] <= rd_v;
                valid[rd_s] <= 1'b1;
            end
            if (valid_we) begin
                valid[commit_rd_s] <= rd_valid;
            end
            if (push) begin
                valid[prf_tail] <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_v <= 'x;
            rs2_v <= 'x;
            rs1_valid <= 'x;
            rs2_valid <= 'x;
        end else if (~stall) begin
            if (regf_we && rs1_s == rd_s && ~(push && rs1_s == prf_tail)) begin
                rs1_valid <= 1'b1;
            end
            // else if (push && rs1_s == prf_tail) begin
            //     rs1_valid <= 1'b0;
            // end
            else begin
                rs1_valid <= valid[rs1_s];
            end

            if (regf_we && rs2_s == rd_s && ~(push && rs2_s == prf_tail)) begin
                rs2_valid <= 1'b1;
            end
            // else if (push && rs2_s == prf_tail) begin
            //     rs2_valid <= 1'b0;
            // end
            else begin
                rs2_valid <= valid[rs2_s];
            end
            // rs1_valid <= (rs1_s != {(PHYS_REG_BITS){1'b0}}) ? valid[rs1_s] : '0;
            // rs2_valid <= (rs2_s != {(PHYS_REG_BITS){1'b0}}) ? valid[rs2_s] : '0;

            if (regf_we && rs1_s == rd_s) begin
                rs1_v <= rd_v;
            end
            else begin
                rs1_v <= data[rs1_s];
            end

            if (regf_we && rs2_s == rd_s) begin
                rs2_v <= rd_v;
            end
            else begin
                rs2_v <= data[rs2_s];
            end

            // rs1_v <= (rs1_s != {(PHYS_REG_BITS){1'b0}}) ? data[rs1_s] : '0;
            // rs2_v <= (rs2_s != {(PHYS_REG_BITS){1'b0}}) ? data[rs2_s] : '0;
        end
    end

endmodule : prf