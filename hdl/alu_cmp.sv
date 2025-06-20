module alu_cmp
import rv32i_types::*;
(
    input   ooo_instr_t             alu_cmp_instr_struct,
    input   ctrl_word_t             alu_cmp_ctrl_word,

    output  ooo_instr_t             alu_cmp_out_instr_struct
);

        logic   [31:0]  a;
        logic   [31:0]  b;
        logic signed   [31:0] as;
        logic signed   [31:0] bs;
        logic unsigned [31:0] au;
        logic unsigned [31:0] bu;

        logic   [31:0] cmp_a;
        logic   [31:0] cmp_b;
        logic signed   [31:0] cmp_as;
        logic signed   [31:0] cmp_bs;
        logic unsigned [31:0] cmp_au;
        logic unsigned [31:0] cmp_bu;

        logic   [2:0]   aluop;
        logic   [2:0]   cmpop;

        logic   [31:0]  aluout;
        logic   [31:0]  cmpout;
        logic           br_en;

        logic   [31:0]  rs1_value;
        logic   [31:0]  rs2_value;

        assign as =   signed'(a);
        assign bs =   signed'(b);
        assign au = unsigned'(a);
        assign bu = unsigned'(b);

        assign cmp_as =   signed'(cmp_a);
        assign cmp_bs =   signed'(cmp_b);
        assign cmp_au = unsigned'(cmp_a);
        assign cmp_bu = unsigned'(cmp_b);

        always_comb begin
            unique case (aluop)
                alu_op_add: aluout = au +   bu;
                alu_op_sll: aluout = au <<  bu[4:0];
                alu_op_sra: aluout = unsigned'(as >>> bu[4:0]);
                alu_op_sub: aluout = au -   bu;
                alu_op_xor: aluout = au ^   bu;
                alu_op_srl: aluout = au >>  bu[4:0];
                alu_op_or : aluout = au |   bu;
                alu_op_and: aluout = au &   bu;
                default   : aluout = '0;
            endcase
        end

        always_comb begin
            unique case (cmpop)
                branch_f3_beq : begin br_en = (cmp_au == cmp_bu); end
                branch_f3_bne : begin br_en = (cmp_au != cmp_bu); end
                branch_f3_blt : begin br_en = (cmp_as <  cmp_bs); end
                branch_f3_bge : begin br_en = (cmp_as >= cmp_bs); end
                branch_f3_bltu: begin br_en = (cmp_au <  cmp_bu); end
                branch_f3_bgeu: begin br_en = (cmp_au >= cmp_bu); end
                default       : begin br_en = 1'b0; end
            endcase
        end

        always_comb begin
            alu_cmp_out_instr_struct = alu_cmp_instr_struct;

            aluop = alu_cmp_ctrl_word.alu_op;
            cmpop = alu_cmp_ctrl_word.cmp_op;

            a = alu_cmp_instr_struct.rs1_data;
            if (alu_cmp_ctrl_word.alu_m1_sel) begin
                a = alu_cmp_instr_struct.pc;
            end

            b = alu_cmp_instr_struct.rs2_data;
            if (alu_cmp_ctrl_word.alu_m2_sel) begin
                b = alu_cmp_instr_struct.imm;
            end

            cmp_a = alu_cmp_instr_struct.rs1_data;
            cmp_b = b;

            cmpout = {31'b0, br_en};

            if (alu_cmp_ctrl_word.alu_cmp_sel) begin
                alu_cmp_out_instr_struct.rd_data = cmpout;
            end
            else begin
                alu_cmp_out_instr_struct.rd_data = aluout;
            end
        end


endmodule : alu_cmp