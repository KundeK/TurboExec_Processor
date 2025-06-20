module dp_stage
import rv32i_types::*;    
(
    input   ctrl_word_t         rd_dp_ctrl_word,
    input   ooo_instr_t         rd_dp_instr_struct,

    input   logic               prf_rs1_valid, prf_rs2_valid,
    input   logic   [31:0]      prf_rs1_v, prf_rs2_v,

    // input   logic               wb_valid,
    // input   logic   [31:0]      wb_data,
    // input   logic   [PHYS_REG_BITS-1:0] wb_paddr,
    input   wb_bus_t            wb_bus,

    output  ctrl_word_t         dp_ctrl_word,
    output  ooo_instr_t         dp_instr_struct,

    output  logic               dp_rs_valid,
    output  logic               in_dp_wb_rs1, in_dp_wb_rs2
);

    always_comb begin
        dp_ctrl_word = rd_dp_ctrl_word;
        dp_instr_struct = rd_dp_instr_struct;

        dp_rs_valid = 1'b0;
        in_dp_wb_rs1 = 1'b0;
        in_dp_wb_rs2 = 1'b0;

        // not set ready in rd so attempt fill with prf
        // used check later in issue
        if (~rd_dp_instr_struct.rs1_rdy & prf_rs1_valid) begin
            dp_instr_struct.rs1_rdy = 1'b1;
            dp_instr_struct.rs1_data = prf_rs1_v;
        end
        else if (wb_bus.valid & ~rd_dp_instr_struct.rs1_rdy & 
                 rd_dp_instr_struct.rs1_paddr == wb_bus.rd_paddr) begin
            in_dp_wb_rs1 = 1'b1;
            dp_instr_struct.rs1_rdy = 1'b1;
            dp_instr_struct.rs1_data = wb_bus.rd_data;
        end

        if (~rd_dp_instr_struct.rs2_rdy & prf_rs2_valid) begin
            dp_instr_struct.rs2_rdy = 1'b1;
            dp_instr_struct.rs2_data = prf_rs2_v;
        end
        else if (wb_bus.valid & ~rd_dp_instr_struct.rs2_rdy & 
                 rd_dp_instr_struct.rs2_paddr == wb_bus.rd_paddr) begin
            in_dp_wb_rs2 = 1'b1;
            dp_instr_struct.rs2_rdy = 1'b1;
            dp_instr_struct.rs2_data = wb_bus.rd_data;
        end

        // check relavant RSs based on instr type then fill open one
        if (rd_dp_instr_struct.valid) begin
            dp_rs_valid = 1'b1;
        end

    end

endmodule : dp_stage