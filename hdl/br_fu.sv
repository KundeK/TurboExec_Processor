module br_fu
import rv32i_types::*;
(
    // Reservation station interface
    input   ooo_instr_t         br_issue_instr, // Instruction from RS
    input   ctrl_word_t         br_ctrl_word,
    
    // Writeback interface
    output  ooo_instr_t         BR_out             // Result to writeback
);

    logic   [31:0] cmp_a;
    logic   [31:0] cmp_b;
    logic signed   [31:0] cmp_as;
    logic signed   [31:0] cmp_bs;
    logic unsigned [31:0] cmp_au;
    logic unsigned [31:0] cmp_bu;

    logic   [2:0]   cmpop;

    logic   [31:0]  cmpout;
    logic           br_en;

    assign cmpop = br_ctrl_word.cmp_op;
    assign cmp_a = br_issue_instr.rs1_data;
    assign cmp_b = br_issue_instr.rs2_data;
    assign cmp_as =   signed'(cmp_a);
    assign cmp_bs =   signed'(cmp_b);
    assign cmp_au = unsigned'(cmp_a);
    assign cmp_bu = unsigned'(cmp_b);

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
        BR_out = br_issue_instr;
        case (br_issue_instr.data.r_type.opcode)
            op_b_jal : begin
                BR_out.rd_data = br_issue_instr.pc + 'd4;
                BR_out.br_addr = br_issue_instr.pc + br_issue_instr.imm;
                BR_out.br_en = 1'b1; 
            end
            op_b_jalr : begin
                BR_out.rd_data = br_issue_instr.pc + 'd4;
                BR_out.br_addr = (br_issue_instr.rs1_data + br_issue_instr.imm) & 32'hfffffffe;
                BR_out.br_en = 1'b1;
            end
            op_b_br : begin
                if(br_en) begin
                    BR_out.br_addr = br_issue_instr.pc + br_issue_instr.imm;
                end
                BR_out.br_en = br_en;
            end
            default : begin
                BR_out = '0;
            end
        endcase
    end

endmodule : br_fu