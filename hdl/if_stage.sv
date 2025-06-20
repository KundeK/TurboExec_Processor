module if_stage
import rv32i_types::*;
(
    input   logic   [31:0]  pc,
    input   logic   [63:0]  order,
    input   logic   [31:0]  pc_next,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    // input   logic           branched,
    // input   logic           imem_discard,

    // input   logic           mm_bub,

    output  if_id_t         if_id
);

    always_comb begin
        // imem_addr = pc + 'd4;
        imem_addr = pc;
        imem_rmask = 4'b1111;

        if_id.inst = imem_rdata;
        if_id.load_ir = 1'b0;
        if (imem_resp) begin
            if_id.load_ir = 1'b1;
            // if_id.inst = imem_rdata;
        end

        if_id.pc = pc;
        if_id.order = order;

        if_id.ctrl_word = '0;

        if_id.monitor = '0;
        if_id.monitor.valid = 1'b0;

        if_id.monitor.order = order;
        // if_id.monitor.inst = imem_rdata;
        if_id.monitor.inst = if_id.inst;
        if_id.monitor.pc_rdata = pc;
        if_id.monitor.pc_wdata = pc_next;
        if_id.monitor.mem_addr = pc;
        if_id.monitor.mem_rmask = 4'b0000;
        if_id.monitor.mem_wmask = 4'b0000;
        if_id.monitor.mem_rdata = imem_rdata;
        if_id.monitor.mem_wdata = 'b0;

        // if (branched || (imem_discard && ~imem_discard)) begin
        //     if_id.ctrl_word.invalid = 1'b1;
        // end
        // if (branched || imem_discard || mm_bub) begin
        //     if_id.ctrl_word.invalid = 1'b1;
        // end
    end

endmodule : if_stage