module rob 
import rv32i_types::*;
(
    input   logic   clk,
    input   logic   rst,

    // pushing instruction from rename
    input   logic           push_instr,
    input   ooo_instr_t     data_entry,
    // input   logic           [PHYS_REG_BITS-1:0]rd_paddr,
    // input   logic           [4:0]rd_aaddr,

    output  logic           [ROB_NUM_BITS-1:0]tail_addr,
    output  logic           instr_resp,

    // pushing completed status from writeback
    input   logic           push_status,
    input   logic           [ROB_NUM_BITS-1:0]rob_addr,
    input   ooo_instr_t     wb_instr_struct,

    input   wb_bus_t        wb_bus,

    // popping completed instructions to commit
    // input   logic           pop,     // don't need to externally call pop (just pop when head is done)

    output  rob_entry_t     rob_pop_data,
    output  logic           pop_resp,
    output  monitor_t       monitor,

    output  logic           rob_head_mem_req,
    output  ooo_instr_t     rob_head_instr,
    output  logic           br_mispredict      // on pop, 0 - prediction correct, 1 - prediction incorrect
    // output  logic           rob_full
);
    localparam              DEPTH = 2**ROB_NUM_BITS;

    rob_entry_t             internal_rob[DEPTH];    
    logic   [ROB_NUM_BITS:0]    head_reg, tail_reg;

    rob_entry_t     rob_in;
    // logic   [31:0]  instr_data;
    // logic   [4:0]   rd_addr;
    // logic   [PHYS_REG_BITS-1:0] rd_paddr;

    logic   full, empty, valid;

    assign  full = (head_reg[ROB_NUM_BITS] != tail_reg[ROB_NUM_BITS]
                        && head_reg[ROB_NUM_BITS-1:0] == tail_reg[ROB_NUM_BITS-1:0]);
    assign  empty = (head_reg[ROB_NUM_BITS] == tail_reg[ROB_NUM_BITS]
                        && head_reg[ROB_NUM_BITS-1:0] == tail_reg[ROB_NUM_BITS-1:0]);
    assign  valid =  (full) || 
                        (head_reg[ROB_NUM_BITS] == tail_reg[ROB_NUM_BITS] && rob_addr >= head_reg[ROB_NUM_BITS-1:0] && rob_addr < tail_reg[ROB_NUM_BITS-1:0]) ||
                        (head_reg[ROB_NUM_BITS] != tail_reg[ROB_NUM_BITS] && (rob_addr >= head_reg[ROB_NUM_BITS-1:0] || rob_addr < tail_reg[ROB_NUM_BITS-1:0]));
    
    assign instr_resp = ~full;

    assign rob_head_mem_req = ~empty & internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.instr_type == mem
                                & internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.valid & ~br_mispredict;

    assign rob_head_instr = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data;

    always_ff @(posedge clk) begin
        if(rst) begin
            head_reg <= '0;
            tail_reg <= '0;
            // instr_resp <= '0;
            // status_resp <= '0;
        end else begin
            // instr_resp <= '0;
            // status_resp <= '0;
            if(internal_rob[head_reg[ROB_NUM_BITS-1:0]].status) begin
                if(!empty) begin
                    head_reg[ROB_NUM_BITS:0] <= head_reg[ROB_NUM_BITS:0] + 1'b1;
                end
            end
            if(push_instr) begin
                if(!full) begin
                    internal_rob[tail_reg[ROB_NUM_BITS-1:0]] <= rob_in; // {1'b0, instr_data, rd_addr, rd_paddr};
                    // tail_addr <= tail_reg[ROB_NUM_BITS-1:0];
                    tail_reg[ROB_NUM_BITS:0] <= tail_reg[ROB_NUM_BITS:0] + 1'b1;
                    // instr_resp <= '1;
                end
            end
            if(push_status) begin
                if(valid) begin
                    internal_rob[rob_addr].status <= '1;
                    internal_rob[rob_addr].data.rd_data <= wb_bus.rd_data;
                    internal_rob[rob_addr].data.rs1_data <= wb_instr_struct.rs1_data;
                    internal_rob[rob_addr].data.rs2_data <= wb_instr_struct.rs2_data;
                    internal_rob[rob_addr].data.rd_paddr <= wb_instr_struct.rd_paddr;
                    // update branching fields
                    internal_rob[rob_addr].data.br_addr <= wb_instr_struct.br_addr;
                    internal_rob[rob_addr].data.br_en <= wb_instr_struct.br_en;
                    // status_resp <= '1;
                    internal_rob[rob_addr].data.mem_addr <= wb_instr_struct.mem_addr;
                    internal_rob[rob_addr].data.mem_wmask <= wb_instr_struct.mem_wmask;
                    internal_rob[rob_addr].data.mem_rmask <= wb_instr_struct.mem_rmask;
                    internal_rob[rob_addr].data.mem_rdata <= wb_instr_struct.mem_rdata;
                    internal_rob[rob_addr].data.mem_wdata <= wb_instr_struct.mem_wdata;
                end
            end
        end    
    end

    always_comb begin
        rob_in.status = 1'b0;
        // rob_in.valid
        rob_in.data = data_entry;
        // rob_in.monitor = data_entry.monitor;
        rob_in.rd_addr = data_entry.rd_addr;
        rob_in.rd_paddr = data_entry.rd_paddr;

        monitor = '0;
        br_mispredict = '0;

        // combination pop
        rob_pop_data = '0;  // rob_pop_data is invalid
        pop_resp = '0;
        if(internal_rob[head_reg[ROB_NUM_BITS-1:0]].status) begin
            if(!empty) begin
                rob_pop_data = internal_rob[head_reg[ROB_NUM_BITS-1:0]];
                pop_resp = '1;

                monitor.valid = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.valid;
                monitor.order = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.order;
                monitor.inst = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.data;
                monitor.rs1_addr = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rs1_addr;
                monitor.rs2_addr = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rs2_addr;
                monitor.rs1_rdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rs1_data;
                monitor.rs2_rdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rs2_data;
                monitor.rd_addr = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rd_addr;
                monitor.rd_wdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.rd_data;
                monitor.pc_rdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.pc;
                // change to add a pc next field in instr struct
                monitor.pc_wdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.pc + 'd4;
                // change after adding mem instr
                monitor.mem_addr = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.mem_addr;
                monitor.mem_wmask = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.mem_wmask;
                monitor.mem_rmask = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.mem_rmask;
                monitor.mem_rdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.mem_rdata;
                monitor.mem_wdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.mem_wdata;

                // determine prediction status for branch instructions and set pc_next to br_addr
                if(internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.data.r_type.opcode inside {op_b_br, op_b_jal, op_b_jalr}) begin
                    if(internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.br_en) begin
                        monitor.pc_wdata = internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.br_addr;
                    end
                    if(internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.br_en != internal_rob[head_reg[ROB_NUM_BITS-1:0]].data.br_predict) begin
                        br_mispredict = '1;
                    end
                end
            end
        end

        tail_addr = 'x;
        if (push_instr) begin
            if (~full) begin
                tail_addr = tail_reg[ROB_NUM_BITS-1:0];
            end
        end
    end

endmodule : rob