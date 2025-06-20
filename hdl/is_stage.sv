module is_stage
import rv32i_types::*;
(
    output  logic               alu_rs_instr_req,
    output  logic               mul_rs_instr_req,
    output  logic               div_rs_instr_req,
    output  logic               mem_rs_instr_req,
    output  logic               br_rs_instr_req,

    input   ooo_instr_t         alu_rs_instr_struct,
    input   ooo_instr_t         mul_rs_instr_struct,
    input   ooo_instr_t         div_rs_instr_struct,
    input   ooo_instr_t         mem_rs_instr_struct,
    input   ooo_instr_t         br_rs_instr_struct,

    input   ctrl_word_t         alu_rs_ctrl_word,
    input   ctrl_word_t         mul_rs_ctrl_word,
    input   ctrl_word_t         div_rs_ctrl_word,
    input   ctrl_word_t         mem_rs_ctrl_word,
    input   ctrl_word_t         br_rs_ctrl_word,

    input   logic               alu_fu_busy,
    input   logic               mul_fu_busy,
    input   logic               div_fu_busy,
    input   logic               mem_fu_busy,

    input   logic               rob_head_mem_req,
    input   logic               br_fu_busy,

    input   logic               alu_wb_resp,
    input   logic               mul_wb_resp,
    input   logic               div_wb_resp,
    input   logic               mem_wb_resp,
    input   logic               br_wb_resp,

    output  ooo_instr_t         alu_fu_instr_struct,
    output  ooo_instr_t         mul_fu_instr_struct,
    output  ooo_instr_t         div_fu_instr_struct,
    output  ooo_instr_t         mem_fu_instr_struct,
    output  ooo_instr_t         br_fu_instr_struct,

    output  ctrl_word_t         alu_fu_ctrl_word,
    output  ctrl_word_t         mul_fu_ctrl_word,
    output  ctrl_word_t         div_fu_ctrl_word,
    output  ctrl_word_t         mem_fu_ctrl_word,
    output  ctrl_word_t         br_fu_ctrl_word
);

//  used is reg in cpu, set high when instr in fu goes valid,
//  set low when wb resp high

    always_comb begin
        alu_rs_instr_req = 1'b0;
        mul_rs_instr_req = 1'b0;
        div_rs_instr_req = 1'b0;
        mem_rs_instr_req = 1'b0;
        br_rs_instr_req = 1'b0;

        alu_fu_instr_struct = '0;
        mul_fu_instr_struct = '0;
        div_fu_instr_struct = '0;
        mem_fu_instr_struct = '0;
        br_fu_instr_struct = '0;

        alu_fu_ctrl_word = '0;
        mul_fu_ctrl_word = '0;
        div_fu_ctrl_word = '0;
        mem_fu_ctrl_word = '0;
        br_fu_ctrl_word = '0;

        // req if FU can take instr
        if (~(alu_fu_busy & ~alu_wb_resp)) begin
            alu_rs_instr_req = 1'b1;

            if (alu_rs_instr_struct.valid) begin
                alu_fu_instr_struct = alu_rs_instr_struct;
                alu_fu_ctrl_word = alu_rs_ctrl_word;
            end
        end
        if (~(mul_fu_busy & (~mul_wb_resp | mul_wb_resp))) begin
            mul_rs_instr_req = 1'b1;

            if (mul_rs_instr_struct.valid) begin
                mul_fu_instr_struct = mul_rs_instr_struct;
                mul_fu_ctrl_word = mul_rs_ctrl_word;
            end
        end
        if (~(div_fu_busy & (~div_wb_resp | div_wb_resp))) begin
            div_rs_instr_req = 1'b1;

            if (div_rs_instr_struct.valid) begin
                div_fu_instr_struct = div_rs_instr_struct;
                div_fu_ctrl_word = div_rs_ctrl_word;
            end
        end

        // if (~(mem_fu_busy & (~mem_wb_resp | mem_wb_resp))) begin
        if (rob_head_mem_req & ~mem_fu_busy & (mem_wb_resp | ~mem_wb_resp)) begin
            mem_rs_instr_req = 1'b1;

            if (mem_rs_instr_struct.valid) begin
                mem_fu_instr_struct = mem_rs_instr_struct;
                mem_fu_ctrl_word = mem_rs_ctrl_word;
            end
        end

        if (~(br_fu_busy & ~br_wb_resp)) begin
            br_rs_instr_req = 1'b1;

            if (br_rs_instr_struct.valid) begin
                br_fu_instr_struct = br_rs_instr_struct;
                br_fu_ctrl_word = br_rs_ctrl_word;
            end
        end
    end

endmodule : is_stage