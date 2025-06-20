module id_stage
import rv32i_types::*;    
(
    output  logic               instr_q_pop,
    input   logic   [127:0]     instr_data,
    // input   logic   [31:0]      instr_data,
    input   logic               pop_resp,

    input   logic               stall,
    // input   logic               flush,

    output  ctrl_word_t         id_rd_ctrl_word,
    output  ooo_instr_t         id_rd_instr_struct
);

        logic   [2:0]   funct3;
        logic   [6:0]   funct7;
        logic   [6:0]   opcode;
        logic   [31:0]  i_imm;
        logic   [31:0]  s_imm;
        logic   [31:0]  b_imm;
        logic   [31:0]  u_imm;
        logic   [31:0]  j_imm;
        logic   [4:0]   rs1_s;
        logic   [4:0]   rs2_s;
        logic   [4:0]   rd_s;

        logic   [31:0]  inst;

        logic           valid;
        logic           regf_we;

    assign inst = instr_data[31:0];

    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign opcode = inst[6:0];
    assign i_imm  = {{21{inst[31]}}, inst[30:20]};
    assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
    assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign u_imm  = {inst[31:12], 12'h000};
    assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
    assign rs1_s  = inst[19:15];
    assign rs2_s  = inst[24:20];
    assign rd_s   = inst[11:7];


    always_comb begin
        id_rd_ctrl_word = '0;
        id_rd_instr_struct = '0;
        // instr_struct.valid = 1'b0;

        id_rd_instr_struct.pc = instr_data[63:32];
        id_rd_instr_struct.order = instr_data[127:64];

        instr_q_pop = 1'b0;
        if (~stall) begin
            instr_q_pop = 1'b1;
        end

        if (pop_resp) begin
            unique case (opcode)
                op_b_lui    : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = alu;

                    // instr_struct.rs1_addr = 
                    id_rd_instr_struct.imm = u_imm;

                    id_rd_instr_struct.rs1_addr = 5'b0;
                    id_rd_instr_struct.rs1_used = 1'b1;

                    id_rd_instr_struct.rd_addr = rd_s;

                    id_rd_ctrl_word.alu_m1_sel = rs1_out;
                    id_rd_ctrl_word.alu_m2_sel = imm_out;
                    id_rd_ctrl_word.alu_cmp_sel = alu_out;
                    id_rd_ctrl_word.alu_op = alu_op_add;
                end
                op_b_auipc  : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = alu;

                    id_rd_instr_struct.imm = u_imm;

                    id_rd_instr_struct.rd_addr = rd_s;

                    id_rd_ctrl_word.alu_m1_sel = pc_out;
                    id_rd_ctrl_word.alu_m2_sel = imm_out;
                    id_rd_ctrl_word.alu_cmp_sel = alu_out;
                    id_rd_ctrl_word.alu_op = alu_op_add;
                end
                op_b_jal    : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = br;

                    // instr_struct.rs1_addr = 
                    id_rd_instr_struct.imm = j_imm;

                    id_rd_instr_struct.rs1_used = 1'b0;
                    id_rd_instr_struct.rs2_used = 1'b0;

                    id_rd_instr_struct.rd_addr = rd_s;
                end
                op_b_jalr   : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = br;

                    id_rd_instr_struct.imm = i_imm;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs1_used = 1'b1;
                    id_rd_instr_struct.rs2_used = 1'b0;

                    id_rd_instr_struct.rd_addr = rd_s;
                end
                op_b_br     : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = br;

                    id_rd_instr_struct.imm = b_imm;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs2_addr = rs2_s;
                    id_rd_instr_struct.rs1_used = 1'b1;
                    id_rd_instr_struct.rs2_used = 1'b1;

                    id_rd_ctrl_word.cmp_op = branch_f3_t'(funct3);
                end
                op_b_load   : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = mem;

                    id_rd_instr_struct.imm = i_imm;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs1_used = 1'b1;

                    id_rd_instr_struct.rd_addr = rd_s;

                    id_rd_ctrl_word.mm_op_sel = ld;
                end
                op_b_store  : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = mem;

                    id_rd_instr_struct.imm = s_imm;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs1_used = 1'b1;

                    id_rd_instr_struct.rs2_addr = rs2_s;
                    id_rd_instr_struct.rs2_used = 1'b1;

                    id_rd_ctrl_word.mm_op_sel = st;
                end
                op_b_imm    : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;
                    id_rd_instr_struct.instr_type = alu;
                    
                    id_rd_instr_struct.imm = i_imm;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs1_used = 1'b1;

                    id_rd_instr_struct.rd_addr = rd_s;

                    id_rd_ctrl_word.alu_m1_sel = rs1_out;
                    id_rd_ctrl_word.alu_m2_sel = imm_out;

                    unique case (funct3)
                        arith_f3_slt: begin
                            id_rd_ctrl_word.alu_cmp_sel = cmp_out;
                            id_rd_ctrl_word.cmp_op = branch_f3_blt;
                        end
                        arith_f3_sltu: begin
                            id_rd_ctrl_word.alu_cmp_sel = cmp_out;
                            id_rd_ctrl_word.cmp_op = branch_f3_bltu;
                        end
                        arith_f3_sr: begin
                            id_rd_ctrl_word.alu_cmp_sel = alu_out;

                            if (funct7[5]) begin
                                id_rd_ctrl_word.alu_op = alu_op_sra;
                            end else begin
                                id_rd_ctrl_word.alu_op = alu_op_srl;
                            end
                        end
                        default: begin
                            id_rd_ctrl_word.alu_cmp_sel = alu_out;
                            id_rd_ctrl_word.alu_op = alu_ops'(funct3);
                        end
                    endcase
                end
                op_b_reg    : begin
                    id_rd_instr_struct.valid = 1'b1;

                    id_rd_instr_struct.data = inst;

                    id_rd_instr_struct.rs1_addr = rs1_s;
                    id_rd_instr_struct.rs1_used = 1'b1;

                    id_rd_instr_struct.rs2_addr = rs2_s;
                    id_rd_instr_struct.rs2_used = 1'b1;

                    id_rd_instr_struct.rd_addr = rd_s;

                    id_rd_ctrl_word.alu_m1_sel = rs1_out;
                    id_rd_ctrl_word.alu_m2_sel = rs2_out;

                    // mult/div ops
                    if (funct7[0]) begin
                        if (funct3 <= 3'd3) begin
                            id_rd_instr_struct.instr_type = mult;
                        end
                        else begin
                            id_rd_instr_struct.instr_type = div;
                        end
                    end
                    // largely same as pipeline
                    else begin
                        id_rd_instr_struct.instr_type = alu;

                        id_rd_ctrl_word.alu_m1_sel = rs1_out;
                        id_rd_ctrl_word.alu_m2_sel = rs2_out;

                        unique case (funct3)
                            arith_f3_slt: begin
                                id_rd_ctrl_word.alu_cmp_sel = cmp_out;
                                id_rd_ctrl_word.cmp_op = branch_f3_blt;
                            end
                            arith_f3_sltu: begin
                                id_rd_ctrl_word.alu_cmp_sel = cmp_out;
                                id_rd_ctrl_word.cmp_op = branch_f3_bltu;
                            end
                            arith_f3_sr: begin
                                id_rd_ctrl_word.alu_cmp_sel = alu_out;
    
                                if (funct7[5]) begin
                                    id_rd_ctrl_word.alu_op = alu_op_sra;
                                end else begin
                                    id_rd_ctrl_word.alu_op = alu_op_srl;
                                end
                            end
                            arith_f3_add: begin
                                id_rd_ctrl_word.alu_cmp_sel = alu_out;
    
                                if (funct7[5]) begin
                                    id_rd_ctrl_word.alu_op = alu_op_sub;
                                end else begin
                                    id_rd_ctrl_word.alu_op = alu_op_add;
                                end
                            end
                            default: begin
                                id_rd_ctrl_word.alu_cmp_sel = alu_out;
                                id_rd_ctrl_word.alu_op = alu_ops'(funct3);
                            end
                        endcase
                    end
                end
                default     : begin
                end
            endcase
        end
    end

endmodule : id_stage