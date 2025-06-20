module rd_stage
import rv32i_types::*;    
(
    input   ctrl_word_t         id_rd_ctrl_word,
    input   ooo_instr_t         id_rd_instr_struct,

    input   logic               rs1_valid, rs2_valid,
    input   logic   [31:0]      rs1_data, rs2_data,
    input   logic               rs1_renamed, rs2_renamed,
    input   logic   [PHYS_REG_BITS-1:0] rs1_paddr, rs2_paddr,

    input   logic   [PHYS_REG_BITS-1:0] prf_pop_data,
    input   logic               prf_pop_resp,

    input   logic               stall,

    output  ctrl_word_t         rd_dp_ctrl_word,
    output  ooo_instr_t         rd_dp_instr_struct,

    output  logic               arf_we_rename, arf_we_paddr,
    output  logic   [4:0]       arf_rename_s, arf_paddr_s,
    output  logic               arf_rename_v,
    output  logic   [PHYS_REG_BITS-1:0] arf_paddr_v,

    output  logic   [PHYS_REG_BITS-1:0] prf_rs1_s, prf_rs2_s,
    output  logic               prf_pop,

    output  logic               rob_req,
    output  ooo_instr_t         rob_data_entry,

    input   logic   [ROB_NUM_BITS-1:0]  rob_addr,
    input   logic                       rob_resp,
    
    input   logic               br_predict
);
// need to add ROB update as well

    always_comb begin
        rd_dp_ctrl_word = id_rd_ctrl_word;
        rd_dp_instr_struct = id_rd_instr_struct;

        prf_pop = 1'b0;

        // req paddrs for next cycle
        prf_rs1_s = rs1_paddr;
        prf_rs2_s = rs2_paddr;

        rd_dp_instr_struct.rs1_paddr = rs1_paddr;
        rd_dp_instr_struct.rs2_paddr = rs2_paddr;

        rob_req = 1'b0;
        rob_data_entry = '0;

        arf_we_rename = 1'b0;
        arf_we_paddr = 1'b0;
        arf_rename_s = 5'b0;
        arf_rename_v = 'x;
        arf_paddr_s = 5'b0;
        arf_paddr_v = '0;

        // set branch prediction
        rd_dp_instr_struct.br_predict = br_predict;

        // req paddr for rd
        if (~stall & id_rd_instr_struct.valid) begin
            prf_pop = 1'b1;
        end
        // if (id_rd_instr_struct.valid & (stall | ~stall)) begin
        //     prf_pop = 1'b1;
        // end

        if (prf_pop_resp) begin
            rd_dp_instr_struct.rd_paddr = prf_pop_data;

            arf_we_rename = 1'b1;
            arf_we_paddr = 1'b1;

            arf_rename_s = id_rd_instr_struct.rd_addr;
            arf_paddr_s = id_rd_instr_struct.rd_addr;

            arf_rename_v = 1'b1;
            arf_paddr_v = prf_pop_data;
        end

        // set data and ready if not renamed
        if (rs1_valid && ~rs1_renamed) begin
            rd_dp_instr_struct.rs1_data = rs1_data;
            rd_dp_instr_struct.rs1_rdy = 1'b1;
        end
        if (rs2_valid && ~rs2_renamed) begin
            rd_dp_instr_struct.rs2_data = rs2_data;
            rd_dp_instr_struct.rs2_rdy = 1'b1;
        end

        if (~stall & id_rd_instr_struct.valid) begin
            rob_req = 1'b1;
            rob_data_entry = id_rd_instr_struct;
        end

        if (rob_resp) begin
            rd_dp_instr_struct.rob_addr = rob_addr;
        end
    end

endmodule : rd_stage