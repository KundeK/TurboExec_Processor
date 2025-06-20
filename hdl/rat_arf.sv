module rat_arf #(
    parameter               PHYS_REG_BITS = 6
)(
    input   logic           clk,
    input   logic           rst,
    input   logic           br_rst,
    input   logic           stall,
    input   logic           we_rename, we_paddr,
    input   logic   [4:0]   rs1_s, rs2_s,
    input   logic   [4:0]   rename_s, paddr_s,
    input   logic           rename_v,
    input   logic   [PHYS_REG_BITS-1:0] paddr_v,

    // inputs for commit ?
    input   logic           we_rd_rename, we_rd_data,
    input   logic   [4:0]   rd_s,
    input   logic           rd_rename_v,
    input   logic   [31:0]  rd_v,
    input   logic   [PHYS_REG_BITS-1:0] rd_old_paddr,

    output  logic           rs1_valid, rs2_valid,
    output  logic   [31:0]  rs1_data, rs2_data,
    output  logic           rs1_renamed, rs2_renamed,
    output  logic   [PHYS_REG_BITS-1:0] rs1_paddr, rs2_paddr
);

    // logic   [4:0]       valid;
    // logic   [4:0]       data[32];
    // logic   [4:0]       renamed;
    // logic   [4:0]       paddr[PHYS_REG_BITS-1:0];

    logic                   valid[32];
    logic      [31:0]       data[32];
    logic                   renamed[32];
    logic       [PHYS_REG_BITS-1:0] paddr[32];  

    logic       [4:0]       stall_rs1_s;
    logic       [4:0]       stall_rs2_s;

    always_ff @(posedge clk) begin
        if (rst) begin
            for (integer i = 0; i < 32; i++) begin
                valid[i] <= 1'b1;
                data[i] <= 32'b0;

                renamed[i] <= 1'b0;
                paddr[i] <= {PHYS_REG_BITS{1'b0}};
            end

            stall_rs1_s <= 5'b00000;
            stall_rs2_s <= 5'b00000;
        end
        else if (br_rst) begin  // flush all renames but retain ARF data
            for (integer i = 0; i < 32; i++) begin
                valid[i] <= 1'b1;

                renamed[i] <= 1'b0;
                paddr[i] <= {PHYS_REG_BITS{1'b0}};
            end

            if (we_rd_rename && (rd_s != 5'd0) && rd_old_paddr == paddr[rd_s]) begin
                renamed[rd_s] <= rd_rename_v;
            end
            if (we_rd_data && (rd_s != 5'd0)) begin
                data[rd_s] <= rd_v;
            end
        end
        else begin
            if (we_rd_rename && (rd_s != 5'd0) && ~(we_rename && rename_s == rd_s)
                && rd_old_paddr == paddr[rd_s]) begin
                renamed[rd_s] <= rd_rename_v;
            end
            if (we_rename && (rename_s != 5'd0)) begin
                renamed[rename_s] <= rename_v;
            end
            if (we_paddr && (paddr_s != 5'd0)) begin
                paddr[paddr_s] <= paddr_v;
            end
            if (we_rd_data && (rd_s != 5'd0)) begin
                data[rd_s] <= rd_v;
            end
        end

        if (~stall) begin
            stall_rs1_s <= rs1_s;
            stall_rs2_s <= rs2_s;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            rs1_valid <= 'x;
            rs2_valid <= 'x;

            rs1_data <= 'x;
            rs2_data <= 'x;

            rs1_renamed <= 'x;
            rs2_renamed <= 'x;

            rs1_paddr <= 'x;
            rs2_paddr <= 'x;
        end else if (~stall) begin
            rs1_valid <= (rs1_s != 5'd0) ? valid[rs1_s] : 1'b1;
            rs2_valid <= (rs2_s != 5'd0) ? valid[rs2_s] : 1'b1;

            if (rs1_s == rd_s && rs1_s != 5'd0 && we_rd_data) begin
                rs1_data <= rd_v;
            end
            else begin
                rs1_data <= (rs1_s != 5'd0) ? data[rs1_s] : 32'b0;
            end
            if (rs2_s == rd_s && rs2_s != 5'd0 && we_rd_data) begin
                rs2_data <= rd_v;
            end
            else begin
                rs2_data <= (rs2_s != 5'd0) ? data[rs2_s] : 32'b0;
            end

            // rs1_data <= (rs1_s != 5'd0) ? data[rs1_s] : 32'b0;
            // rs2_data <= (rs2_s != 5'd0) ? data[rs2_s] : 32'b0;

            if (rs1_s == rename_s && rs1_s != 5'd0 && we_rename) begin
                rs1_renamed <= rename_v;
            end
            else if (rs1_s == rd_s && rs1_s != 5'd0 && we_rd_rename 
                        && paddr[rs1_s] == rd_old_paddr) begin
                rs1_renamed <= rd_rename_v;
            end
            else begin
                rs1_renamed <= (rs1_s != 5'd0) ? renamed[rs1_s] : 1'b0;
            end

            if (rs2_s == rename_s && rs2_s != 5'd0 && we_rename) begin
                rs2_renamed <= rename_v;
            end
            else if (rs2_s == rd_s && rs2_s != 5'd0 && we_rd_rename
                        && paddr[rs2_s] == rd_old_paddr) begin
                rs2_renamed <= rd_rename_v;
            end
            else begin
                rs2_renamed <= (rs2_s != 5'd0) ? renamed[rs2_s] : 1'b0;
            end
            // rs2_renamed <= (rs2_s != 5'd0) ? renamed[rs2_s] : 1'b0;

            if (rs1_s == paddr_s && rs1_s != 5'd0 && we_paddr) begin
                rs1_paddr <= paddr_v;
            end
            else begin
                rs1_paddr <= (rs1_s != 5'd0) ? paddr[rs1_s] : {PHYS_REG_BITS{1'b0}};
            end

            if (rs2_s == paddr_s && rs2_s != 5'd0 && we_paddr) begin
                rs2_paddr <= paddr_v;
            end
            else begin
                rs2_paddr <= (rs2_s != 5'd0) ? paddr[rs2_s] : {PHYS_REG_BITS{1'b0}};
            end

            // rs1_paddr <= (rs1_s != 5'd0) ? paddr[rs1_s] : {PHYS_REG_BITS{1'b0}};
            // rs2_paddr <= (rs2_s != 5'd0) ? paddr[rs2_s] : {PHYS_REG_BITS{1'b0}};
        end
        else begin
            if (stall_rs1_s == rd_s && stall_rs1_s != 5'd0 && we_rd_data) begin
                rs1_data <= rd_v;
            end
            if (stall_rs2_s == rd_s && stall_rs2_s != 5'd0 && we_rd_data) begin
                rs2_data <= rd_v;
            end

            if (stall_rs1_s == rename_s && stall_rs1_s != 5'd0 && we_rename) begin
                rs1_renamed <= rename_v;
            end
            else if (stall_rs1_s == rd_s && stall_rs1_s != 5'd0 && we_rd_rename 
                        && paddr[stall_rs1_s] == rd_old_paddr) begin
                rs1_renamed <= rd_rename_v;
            end
            if (stall_rs2_s == rename_s && stall_rs2_s != 5'd0 && we_rename) begin
                rs2_renamed <= rename_v;
            end
            else if (stall_rs2_s == rd_s && stall_rs2_s != 5'd0 && we_rd_rename 
                        && paddr[stall_rs2_s] == rd_old_paddr) begin
                rs2_renamed <= rd_rename_v;
            end

            if (stall_rs1_s == paddr_s && stall_rs1_s != 5'd0 && we_paddr) begin
                rs1_paddr <= paddr_v;
            end
            if (stall_rs2_s == paddr_s && stall_rs2_s != 5'd0 && we_paddr) begin
                rs1_paddr <= paddr_v;
            end
        end
    end

endmodule : rat_arf