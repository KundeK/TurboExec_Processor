module mem_fu
import rv32i_types::*;    
(
    input   ooo_instr_t         mem_issue_instr,
    input   ctrl_word_t         mem_issue_ctrl_word,

    output  logic   [31:0]      dmem_addr,
    output  logic   [3:0]       dmem_rmask,
    output  logic   [3:0]       dmem_wmask,
    input   logic   [31:0]      dmem_rdata,
    output  logic   [31:0]      dmem_wdata,
    input   logic               dmem_resp,

    // input   logic               wb_resp,
    output  ooo_instr_t         mem_instr_out,

    output  logic               mem_fu_busy
);

    logic   [31:0]      mem_addr;

    assign mem_fu_busy = mem_issue_instr.valid;

    always_comb begin
        dmem_rmask = 4'b0000;
        dmem_wmask = 4'b0000;
        dmem_addr = 'x;
        dmem_wdata = '0;

        mem_instr_out = '0;

        if (mem_issue_instr.valid) begin
            mem_addr = mem_issue_instr.rs1_data + mem_issue_instr.imm;
            dmem_addr = mem_addr & 32'hFFFFFFFC;

            if (mem_issue_ctrl_word.mm_op_sel == st) begin
                unique case (mem_issue_instr.data.i_type.funct3)
                    store_f3_sb: dmem_wmask = 4'b0001 << mem_addr[1:0];
                    store_f3_sh: dmem_wmask = 4'b0011 << mem_addr[1:0];
                    store_f3_sw: dmem_wmask = 4'b1111;
                    default    : dmem_wmask = 4'b0000;
                endcase
                unique case (mem_issue_instr.data.i_type.funct3)
                    store_f3_sb: dmem_wdata[8 *mem_addr[1:0] +: 8 ] = mem_issue_instr.rs2_data[7 :0];
                    store_f3_sh: dmem_wdata[16*mem_addr[1]   +: 16] = mem_issue_instr.rs2_data[15:0];
                    store_f3_sw: dmem_wdata = mem_issue_instr.rs2_data;
                    default    : dmem_wdata = '0;
                endcase
            end 
            else if (mem_issue_ctrl_word.mm_op_sel == ld) begin
                unique case (mem_issue_instr.data.i_type.funct3)
                    load_f3_lb, load_f3_lbu: dmem_rmask = 4'b0001 << mem_addr[1:0];
                    load_f3_lh, load_f3_lhu: dmem_rmask = 4'b0011 << mem_addr[1:0];
                    load_f3_lw             : dmem_rmask = 4'b1111;
                    default                : dmem_rmask = 4'b0000;
                endcase
            end
    

            if (dmem_resp) begin
                mem_instr_out = mem_issue_instr;

                unique case (mem_issue_instr.data.i_type.funct3)
                    load_f3_lb : mem_instr_out.rd_data = {{24{dmem_rdata[7 +8 *mem_addr[1:0]]}}, dmem_rdata[8 *mem_addr[1:0] +: 8 ]};
                    load_f3_lbu: mem_instr_out.rd_data = {{24{1'b0}}                          , dmem_rdata[8 *mem_addr[1:0] +: 8 ]};
                    load_f3_lh : mem_instr_out.rd_data = {{16{dmem_rdata[15+16*mem_addr[1]  ]}}, dmem_rdata[16*mem_addr[1]   +: 16]};
                    load_f3_lhu: mem_instr_out.rd_data = {{16{1'b0}}                          , dmem_rdata[16*mem_addr[1]   +: 16]};
                    load_f3_lw : mem_instr_out.rd_data = dmem_rdata;
                    default    : mem_instr_out.rd_data = 'x;
                endcase

                mem_instr_out.mem_addr = dmem_addr;
                mem_instr_out.mem_wmask = dmem_wmask;
                mem_instr_out.mem_rmask = dmem_rmask;
                mem_instr_out.mem_wdata = dmem_wdata;
                mem_instr_out.mem_rdata = dmem_rdata;
            end

        end
    end

endmodule : mem_fu