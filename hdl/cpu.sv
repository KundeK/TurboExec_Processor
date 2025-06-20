module cpu
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

    logic   [63:0]  order, order_next;
    logic   [31:0]  pc;
    logic   [31:0]  pc_next;

    logic           queue_stall;

    logic           instq_pop;
    // assign instq_pop = 1'b1;

    logic           imem_resp;
    // assign imem_resp 

    logic   [31:0]  imem_addr;
    logic   [3:0]   imem_rmask;
    logic   [31:0]  imem_rdata;

    logic   [31:0]  dmem_addr;
    logic   [3:0]   dmem_rmask;
    logic   [3:0]   dmem_wmask;
    logic   [31:0]  dmem_rdata;
    logic   [31:0]  dmem_wdata;
    logic           dmem_resp;

    logic   [31:0]  buf_addr;
    logic           buf_read;
    logic   [255:0] buf_rdata;
    logic           buf_resp;

    logic   [31:0]  icache_addr;
    logic           icache_read;
    logic           icache_write;
    logic   [255:0] icache_rdata;
    logic   [255:0] icache_wdata;
    logic           icache_resp;

    logic   [31:0]  dcache_addr;
    logic           dcache_read;
    logic           dcache_write;
    logic   [255:0] dcache_rdata;
    logic   [255:0] dcache_wdata;
    logic           dcache_resp;

    logic   [31:0]  adapter_addr;
    logic           adapter_read;
    logic           adapter_write;
    logic   [255:0] adapter_rdata;
    logic   [255:0] adapter_wdata;
    logic           adapter_resp;

    logic           instq_full;
    logic           instq_empty;
    // logic   [31:0]  instq_pop_data;
    logic   [127:0] instq_pop_data;
    logic           instq_pop_resp;
    logic           instq_push_resp;

    logic           prf_regf_we, prf_valid_we, prf_rd_valid;
    logic   [31:0]  prf_rd_v;
    logic   [PHYS_REG_BITS-1:0] prf_rs1_s, prf_rs2_s, prf_rd_s, prf_commit_rd_s;
    logic   [31:0]  prf_rs1_v, prf_rs2_v;
    logic           prf_rs1_valid, prf_rs2_valid;
    logic           fl_push, fl_pop, fl_flush;
    logic           fl_push_resp, fl_pop_resp;
    logic   [PHYS_REG_BITS-1:0] fl_pop_data, fl_head, fl_tail;

    logic           arf_we_rename, arf_we_paddr;
    logic   [4:0]   arf_rs1_s, arf_rs2_s, arf_rename_s, arf_paddr_s;
    logic           arf_rename_v;
    logic   [PHYS_REG_BITS-1:0] arf_paddr_v;
    logic   [PHYS_REG_BITS-1:0] arf_rd_old_paddr;

    logic           arf_rs1_valid, arf_rs2_valid;
    logic   [31:0]  arf_rs1_data, arf_rs2_data;
    logic           arf_rs1_renamed, arf_rs2_renamed;
    logic   [PHYS_REG_BITS-1:0] arf_rs1_paddr, arf_rs2_paddr;

    logic           arf_we_rd_rename, arf_we_rd_data;
    logic   [4:0]   arf_rd_s;
    logic           arf_rd_rename_v;
    logic   [31:0]  arf_rd_v;

    logic           dp_rs_valid;

    logic           add_full, multiply_full, divide_full, mem_full, br_full, rs_stall,
                    add_fu_ready, multiply_fu_ready, divide_fu_ready, br_fu_ready, mem_fu_ready;
    
    ooo_instr_t     add_issue_instr, multiply_issue_instr, divide_issue_instr, mem_issue_instr, br_issue_instr;
    ctrl_word_t     add_issue_ctrl_word, multiply_issue_ctrl_word, divide_issue_ctrl_word, mem_issue_ctrl_word, br_issue_ctrl_word;

    ooo_instr_t     alu_fu_instr_struct, mul_fu_instr_struct, div_fu_instr_struct, br_fu_instr_struct;
    ctrl_word_t     alu_fu_ctrl_word, mul_fu_ctrl_word, div_fu_ctrl_word, br_fu_ctrl_word;

    ooo_instr_t     alu_cmp_out_instr_struct;

    wb_bus_t        wb_bus;

    if_id_t         if_id_reg, if_id_reg_next;

    ctrl_word_t     id_rd_ctrl_word_reg, id_rd_ctrl_word_reg_next;
    ctrl_word_t     rd_dp_ctrl_word_reg, rd_dp_ctrl_word_reg_next;
    ctrl_word_t     dp_ctrl_word_reg, dp_ctrl_word_reg_next;

    ooo_instr_t     id_rd_instr_struct_reg, id_rd_instr_struct_reg_next;
    ooo_instr_t     rd_dp_instr_struct_reg, rd_dp_instr_struct_reg_next;
    ooo_instr_t     dp_instr_struct_reg, dp_instr_struct_reg_next;

    ctrl_word_t     alu_fu_ctrl_word_reg, alu_fu_ctrl_word_reg_next;
    ctrl_word_t     mul_fu_ctrl_word_reg, mul_fu_ctrl_word_reg_next;
    ctrl_word_t     div_fu_ctrl_word_reg, div_fu_ctrl_word_reg_next;
    ctrl_word_t     mem_fu_ctrl_word_reg, mem_fu_ctrl_word_reg_next;
    ctrl_word_t     br_fu_ctrl_word_reg, br_fu_ctrl_word_reg_next;

    ooo_instr_t     alu_fu_instr_struct_reg, alu_fu_instr_struct_reg_next;
    ooo_instr_t     mul_fu_instr_struct_reg, mul_fu_instr_struct_reg_next;
    ooo_instr_t     div_fu_instr_struct_reg, div_fu_instr_struct_reg_next;
    ooo_instr_t     mem_fu_instr_struct_reg, mem_fu_instr_struct_reg_next;
    ooo_instr_t     br_fu_instr_struct_reg, br_fu_instr_struct_reg_next;

    ooo_instr_t     alu_out_instr_struct_reg, alu_out_instr_struct_reg_next;
    ooo_instr_t     mul_out_instr_struct_reg, mul_out_instr_struct_reg_next;
    ooo_instr_t     div_out_instr_struct_reg, div_out_instr_struct_reg_next;
    ooo_instr_t     mem_out_instr_struct_reg, mem_out_instr_struct_reg_next;
    ooo_instr_t     br_out_instr_struct_reg, br_out_instr_struct_reg_next;

    logic           alu_fu_busy, mul_fu_busy, div_fu_busy, br_fu_busy, mem_fu_busy;

    logic           alu_wb_resp, mul_wb_resp, div_wb_resp, mem_wb_resp, br_wb_resp;
    logic           add_issue_req, mul_issue_req, div_issue_req, br_issue_req, mem_issue_req;

    logic           wb_push_status;
    logic   [ROB_NUM_BITS-1:0]  wb_rob_addr;

    ooo_instr_t     wb_instr_struct;

    logic           rd_rob_req;
    ooo_instr_t     rd_rob_data_entry;
    logic   [ROB_NUM_BITS-1:0]  rd_rob_addr;
    logic           rd_rob_resp;

    ooo_instr_t     rob_head_instr;

    rob_entry_t     rob_pop_data;
    logic           rob_pop_resp;
    logic           rob_br_mispredict;
    logic   [3:0]   icache_rmask, dcache_rmask, dcache_wmask;

    logic           rob_head_mem_req;

    monitor_t       monitor;

    logic           br_rst;

    logic           advance_dp, dp_wb_bus_rs1, dp_wb_bus_rs2, in_dp_wb_rs1, in_dp_wb_rs2, dp_wb_en_rs1, dp_wb_en_rs2;
    logic   [31:0]  wb_bus_rs1_reg, wb_bus_rs2_reg;
    // logic           mm_wb_wait;

    logic   [31:0]  pf_addr;
    logic           pf_read, pf_resp;
    logic   [255:0] pf_rdata;

        // assign queue_stall = 1'b0;  // change to queue push resp after integration
        assign queue_stall = instq_full;

        assign arf_rs1_s = id_rd_instr_struct_reg_next.rs1_addr;
        assign arf_rs2_s = id_rd_instr_struct_reg_next.rs2_addr;

        assign arf_we_rd_rename = rob_pop_resp;
        assign arf_we_rd_data = rob_pop_resp;
        assign arf_rd_s = rob_pop_data.data.rd_addr;
        assign arf_rd_rename_v = 1'b0;
        assign arf_rd_v = rob_pop_data.data.rd_data;
        assign arf_rd_old_paddr = rob_pop_data.data.rd_paddr;

        assign prf_regf_we = wb_bus.valid;
        assign prf_rd_s = wb_bus.rd_paddr;
        assign prf_rd_v = wb_bus.rd_data;
        assign prf_commit_rd_s = rob_pop_data.data.rd_paddr;
        // assign prf_commit_rd_valid = 1'b0;
        
        assign prf_valid_we = 1'b0;
        // assign prf_regf_we = 1'b0;
        // assign prf_rd_v = 'x;
        assign prf_rd_valid ='x;
        // assign prf_rd_s = 'x;

        // assign fl_push = 1'b0;
        assign fl_flush = 1'b0;

        // assign alu_wb_resp = 1'b1;
        // assign mul_wb_resp = 1'b1;
        // assign div_wb_resp = 1'b1;
        // assign mem_wb_resp = 1'b1;
        // assign br_wb_resp = 1'b1;

        assign br_rst = rst || rob_br_mispredict;
        assign icache_rmask = rob_br_mispredict ? 4'b0000 : {4{buf_read}};
        assign dcache_rmask = rob_br_mispredict ? 4'b0000 : dmem_rmask;
        assign dcache_wmask = rob_br_mispredict ? 4'b0000 : dmem_wmask;

        assign advance_dp = ~rs_stall && rd_rob_resp && ((~dp_instr_struct_reg.valid || ~dp_instr_struct_reg_next.valid) || ~(dp_instr_struct_reg.pc == dp_instr_struct_reg_next.pc) || ~(dp_instr_struct_reg.order == dp_instr_struct_reg_next.order));
        assign dp_wb_bus_rs1 = wb_bus.valid & ~dp_instr_struct_reg.rs1_rdy & dp_instr_struct_reg.rs1_used & dp_instr_struct_reg.rs1_paddr == wb_bus.rd_paddr;
        assign dp_wb_bus_rs2 = wb_bus.valid & ~dp_instr_struct_reg.rs2_rdy & dp_instr_struct_reg.rs2_used & dp_instr_struct_reg.rs2_paddr == wb_bus.rd_paddr;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc     <= 32'haaaaa000;
            order  <= '0;
        end else begin
            pc <= pc_next;
            order <= order_next;
        end

        // monitor <= monitor_next;
    end

    always_ff @(posedge clk) begin
        if (br_rst) begin
            if_id_reg <= '0;

            id_rd_ctrl_word_reg <= '0;
            rd_dp_ctrl_word_reg <= '0;
            dp_ctrl_word_reg <= '0;

            id_rd_instr_struct_reg <= '0;
            rd_dp_instr_struct_reg <= '0;
            dp_instr_struct_reg <= '0;

            alu_fu_ctrl_word_reg <= '0;
            // mul_fu_ctrl_word_reg <= '0;
            // div_fu_ctrl_word_reg <= '0;
            mem_fu_ctrl_word_reg <= '0;
            br_fu_ctrl_word_reg <= '0;

            alu_fu_instr_struct_reg <= '0;
            mul_fu_instr_struct_reg <= '0;
            div_fu_instr_struct_reg <= '0;
            mem_fu_instr_struct_reg <= '0;
            br_fu_instr_struct_reg <= '0;

            alu_fu_busy <= 1'b0;
            // mul_fu_busy <= 1'b0;
            // div_fu_busy <= 1'b0;
            br_fu_busy <= 1'b0;

            alu_out_instr_struct_reg <= '0;
            mul_out_instr_struct_reg <= '0;
            div_out_instr_struct_reg <= '0;
            mem_out_instr_struct_reg <= '0;
            br_out_instr_struct_reg <= '0;

            // mm_wb_wait <= 1'b0;
            dp_wb_en_rs1 <= 1'b0;
            dp_wb_en_rs2 <= 1'b0;
            // wb_bus_rs1_reg <= '0;
            // wb_bus_rs2_reg <= '0;
        end
        else begin
            if_id_reg <= if_id_reg_next;
            
            // update instr inside dispatch if wb_bus contains rs data
            if(in_dp_wb_rs1) begin
                wb_bus_rs1_reg <= wb_bus.rd_data;
                dp_wb_en_rs1 <= 1'b1;
            end
            if(in_dp_wb_rs2) begin
                wb_bus_rs2_reg <= wb_bus.rd_data;
                dp_wb_en_rs2 <= 1'b1;
            end
            // update instr leaving dispatch if wb_bus contains rs data
            if(~rd_rob_resp & dp_wb_bus_rs1) begin
                dp_wb_en_rs2 <= 1'b0;
                dp_instr_struct_reg.rs1_rdy <= 1'b1;
                dp_instr_struct_reg.rs1_data <= wb_bus.rd_data;
            end
            if(~rd_rob_resp & dp_wb_bus_rs2) begin
                dp_wb_en_rs2 <= 1'b0;
                dp_instr_struct_reg.rs2_rdy <= 1'b1;;
                dp_instr_struct_reg.rs2_data <= wb_bus.rd_data;
            end
            if(advance_dp) begin
                dp_instr_struct_reg <= dp_instr_struct_reg_next;
                dp_ctrl_word_reg <= dp_ctrl_word_reg_next;
                
                dp_wb_en_rs1 <= 1'b0;
                dp_wb_en_rs2 <= 1'b0;
                if(dp_wb_en_rs1) begin
                    dp_instr_struct_reg.rs1_rdy <= 1'b1;
                    dp_instr_struct_reg.rs1_data <= wb_bus_rs1_reg;
                end
                if(dp_wb_en_rs2) begin
                    dp_instr_struct_reg.rs2_rdy <= 1'b1;
                    dp_instr_struct_reg.rs2_data <= wb_bus_rs2_reg;
                end
            end
            // if (wb_bus.valid & ~dp_instr_struct_reg.rs1_rdy & dp_instr_struct_reg.rs1_used & dp_instr_struct_reg.rs1_paddr == wb_bus.rd_paddr) begin
            //     // dp_wb_bus_rs1 = 1'b1;
            //     dp_instr_struct_reg.rs1_rdy <= 1'b1;
            //     dp_instr_struct_reg.rs1_data <= wb_bus.rd_data;
            // end
            // if (wb_bus.valid & ~dp_instr_struct_reg.rs2_rdy & dp_instr_struct_reg.rs2_used & dp_instr_struct_reg.rs2_paddr == wb_bus.rd_paddr) begin
            //     // dp_wb_bus_rs1 = 1'b1;
            //     dp_instr_struct_reg.rs2_rdy <= 1'b1;
            //     dp_instr_struct_reg.rs2_data <= wb_bus.rd_data;
            // end
            // if(~rs_stall && ~rd_rob_resp) begin
            //     dp_instr_struct_reg <= '0;
            // end
            // if(rs_stall) begin
                // dp_instr_struct_reg.valid <= 1'b0;
            // end
            // else begin
            //     dp_instr_struct_reg.valid <= 1'b1;
            // end

            if (~rs_stall & rd_rob_resp) begin
                id_rd_ctrl_word_reg <= id_rd_ctrl_word_reg_next;
                rd_dp_ctrl_word_reg <= rd_dp_ctrl_word_reg_next;
                // dp_ctrl_word_reg <= dp_ctrl_word_reg_next;

                id_rd_instr_struct_reg <= id_rd_instr_struct_reg_next;
                rd_dp_instr_struct_reg <= rd_dp_instr_struct_reg_next;
                // dp_instr_struct_reg <= dp_instr_struct_reg_next;
            end

            mul_fu_instr_struct_reg <= mul_fu_instr_struct_reg_next;
            div_fu_instr_struct_reg <= div_fu_instr_struct_reg_next;

            if (alu_wb_resp | ~alu_out_instr_struct_reg.valid) begin
                alu_fu_instr_struct_reg <= alu_fu_instr_struct_reg_next;
                alu_out_instr_struct_reg <= alu_out_instr_struct_reg_next;
                alu_fu_ctrl_word_reg <= alu_fu_ctrl_word_reg_next;
            end

            if (mul_wb_resp | ~mul_out_instr_struct_reg.valid) begin
                mul_out_instr_struct_reg <= mul_out_instr_struct_reg_next;
            end
            if (div_wb_resp | ~div_out_instr_struct_reg.valid) begin
                div_out_instr_struct_reg <= div_out_instr_struct_reg_next;
            end

            // if (mem_wb_resp) begin
            //     mm_wb_wait <= 1'b0;
            // end
            if (dmem_resp) begin
                mem_fu_instr_struct_reg <= '0;
                mem_fu_ctrl_word_reg <= '0;
                // mem_fu_ctrl_word_reg.mm_op_sel <= no;
            end
            if (~mem_fu_instr_struct_reg.valid) begin
                mem_fu_instr_struct_reg <= mem_fu_instr_struct_reg_next;
                mem_fu_ctrl_word_reg <= mem_fu_ctrl_word_reg_next;
            end
            if (mem_wb_resp | ~mem_out_instr_struct_reg.valid) begin
                mem_out_instr_struct_reg <= mem_out_instr_struct_reg_next;
                // mm_wb_wait <= 1'b1;
            end
            
            if (br_wb_resp | ~br_out_instr_struct_reg.valid) begin
                br_fu_instr_struct_reg <= br_fu_instr_struct_reg_next;
                br_out_instr_struct_reg <= br_out_instr_struct_reg_next;
                br_fu_ctrl_word_reg <= br_fu_ctrl_word_reg_next;
            end


            if (alu_wb_resp) begin
                alu_fu_busy <= 1'b0;
            end
            if (alu_fu_instr_struct_reg.valid) begin
                alu_fu_busy <= 1'b1;
            end

            // if (mul_wb_resp) begin
            //     mul_fu_busy <= 1'b0;
            // end
            // if (mul_fu_instr_struct_reg.valid) begin
            //     mul_fu_busy <= 1'b1;
            // end

            // if (div_wb_resp) begin
            //     div_fu_busy <= 1'b0;
            // end
            // if (div_fu_instr_struct_reg.valid) begin
            //     div_fu_busy <= 1'b1;
            // end

            if (br_wb_resp) begin
                br_fu_busy <= 1'b0;
            end
            if (br_fu_instr_struct_reg.valid) begin
                br_fu_busy <= 1'b1;
            end
        end
    end

    always_comb begin
        pc_next = pc;
        order_next = order;

        if (rob_br_mispredict && rob_pop_data.data.br_en) begin
            pc_next = rob_pop_data.data.br_addr;
            order_next = rob_pop_data.data.order + 'd1;
        end else if (imem_resp && ~queue_stall) begin
            pc_next = pc + 'd4;
            order_next = order + 'd1;
        end

    end

    if_stage if_stage_i (
        .pc(pc),
        .order(order),
        .pc_next(pc_next),
        
        .imem_addr(imem_addr),
        .imem_rmask(imem_rmask),
        .imem_rdata(imem_rdata),
        .imem_resp(imem_resp),

        .if_id(if_id_reg_next)
    );

    queue #(
        .WIDTH(128),
        .NUM_BITS(3)
    ) inst_queue (
        .clk0(clk),
        .rst0(br_rst),

        .push(imem_resp & ~instq_full),
        .pop(instq_pop),
        .push_data({{order}, {pc}, {imem_rdata}}),
        // .push_data(if_id_reg_next.inst),

        .full(instq_full),
        .empty(instq_empty),
        .pop_data(instq_pop_data),
        .pop_resp(instq_pop_resp),
        .push_resp(instq_push_resp)
    );

    id_stage id_stage_i (
        .instr_q_pop(instq_pop),
        .instr_data(instq_pop_data),
        .pop_resp(instq_pop_resp),

        .stall(rs_stall | ~rd_rob_resp),

        .id_rd_ctrl_word(id_rd_ctrl_word_reg_next),
        .id_rd_instr_struct(id_rd_instr_struct_reg_next)
    );

    rd_stage rd_stage_i (
        .id_rd_ctrl_word(id_rd_ctrl_word_reg),
        .id_rd_instr_struct(id_rd_instr_struct_reg),

        .rs1_valid(arf_rs1_valid),
        .rs2_valid(arf_rs2_valid),
        .rs1_data(arf_rs1_data),
        .rs2_data(arf_rs2_data),
        .rs1_renamed(arf_rs1_renamed),
        .rs2_renamed(arf_rs2_renamed),
        .rs1_paddr(arf_rs1_paddr),
        .rs2_paddr(arf_rs2_paddr),

        .prf_pop_data(fl_pop_data),
        .prf_pop_resp(fl_pop_resp),
        .stall(rs_stall | ~rd_rob_resp),

        .rd_dp_ctrl_word(rd_dp_ctrl_word_reg_next),
        .rd_dp_instr_struct(rd_dp_instr_struct_reg_next),

        .prf_pop(fl_pop),

        .rob_req(rd_rob_req),
        .rob_data_entry(rd_rob_data_entry),
        .rob_addr(rd_rob_addr),
        .rob_resp(rd_rob_resp),

        .br_predict(1'b0),
        .*
    );

    dp_stage dp_stage_i (
        .rd_dp_ctrl_word(rd_dp_ctrl_word_reg),
        .rd_dp_instr_struct(rd_dp_instr_struct_reg),

        .dp_ctrl_word(dp_ctrl_word_reg_next),
        .dp_instr_struct(dp_instr_struct_reg_next),
        .dp_rs_valid(dp_rs_valid),
        .*
    );

    reservation_station rs_i (
        .rst(br_rst),

        .dispatch_valid(rd_rob_resp & dp_instr_struct_reg.valid),
        .dispatch_instr(dp_instr_struct_reg),
        .dispatch_ctrl_word(dp_ctrl_word_reg),

        // change once integrating w back end stages
        .wb_bus(wb_bus),
        
        .add_fu_busy(1'b0),
        .multiply_fu_busy(1'b0),
        .divide_fu_busy(1'b0),
        .mem_fu_busy(1'b0),
        .br_fu_busy(1'b0),
        .*
    );

    is_stage is_stage_i (
        .alu_rs_instr_req(add_issue_req),
        .mul_rs_instr_req(mul_issue_req),
        .div_rs_instr_req(div_issue_req),
        .br_rs_instr_req(br_issue_req),
        .mem_rs_instr_req(mem_issue_req),
        
        .alu_rs_instr_struct(add_issue_instr),
        .mul_rs_instr_struct(multiply_issue_instr),
        .div_rs_instr_struct(divide_issue_instr),
        .mem_rs_instr_struct(mem_issue_instr),
        .br_rs_instr_struct(br_issue_instr),

        .alu_rs_ctrl_word(add_issue_ctrl_word),
        .mul_rs_ctrl_word(multiply_issue_ctrl_word),
        .div_rs_ctrl_word(divide_issue_ctrl_word),
        .mem_rs_ctrl_word(mem_issue_ctrl_word),
        .br_rs_ctrl_word(br_issue_ctrl_word),

        .alu_fu_instr_struct(alu_fu_instr_struct_reg_next),
        .mul_fu_instr_struct(mul_fu_instr_struct_reg_next),
        .div_fu_instr_struct(div_fu_instr_struct_reg_next),
        .mem_fu_instr_struct(mem_fu_instr_struct_reg_next),
        .br_fu_instr_struct(br_fu_instr_struct_reg_next),

        .alu_fu_ctrl_word(alu_fu_ctrl_word_reg_next),
        .mul_fu_ctrl_word(mul_fu_ctrl_word_reg_next),
        .div_fu_ctrl_word(div_fu_ctrl_word_reg_next),
        .mem_fu_ctrl_word(mem_fu_ctrl_word_reg_next),
        .br_fu_ctrl_word(br_fu_ctrl_word_reg_next),

        .mem_fu_busy(~(dmem_rmask == 4'b000 && dmem_wmask == 4'b0000)),
        .*
    );

    alu_cmp alu_cmp_i (
        .alu_cmp_instr_struct(alu_fu_instr_struct_reg),
        .alu_cmp_ctrl_word(alu_fu_ctrl_word_reg),
        .alu_cmp_out_instr_struct(alu_out_instr_struct_reg_next)
    );

    multiply_fu #(
        .PHYS_REG_BITS(PHYS_REG_BITS),
        .NUM_STAGES(4)
    ) mult_fu_i (
        .rst(br_rst),

        .multiply_fu_ready(mul_fu_instr_struct_reg.valid),
        .multiply_issue_instr(mul_fu_instr_struct_reg),
        // .multiply_issue_ctrl_word(mul_fu_ctrl_word_reg),

        .MEM_resp(mul_wb_resp),
        .MUL_out(mul_out_instr_struct_reg_next),

        .multiply_fu_busy(mul_fu_busy),
        .*
    );

    divide_fu #(
        .PHYS_REG_BITS(PHYS_REG_BITS),
        .NUM_STAGES(4)
    ) div_fu_i (
        .rst(br_rst),
        
        .divide_fu_ready(div_fu_instr_struct_reg.valid),
        .divide_issue_instr(div_fu_instr_struct_reg),
        // .divide_issue_ctrl_word(div_fu_ctrl_word_reg),

        .FP_resp(div_wb_resp),
        .DIV_out(div_out_instr_struct_reg_next),
        .divide_fu_busy(div_fu_busy),
        .*
    );

    mem_fu mem_fu_i (
        .mem_issue_instr(mem_fu_instr_struct_reg),
        .mem_issue_ctrl_word(mem_fu_ctrl_word_reg),

        .mem_instr_out(mem_out_instr_struct_reg_next),
        .*
    );

    br_fu br_fu_i (
        .br_issue_instr(br_fu_instr_struct_reg),
        .br_ctrl_word(br_fu_ctrl_word_reg),

        .BR_out(br_out_instr_struct_reg_next)
    );

    wb wb_i (
        .ALU_in(alu_out_instr_struct_reg),
        // .MEM_in(mem_out_instr_struct_reg),
        .BR_in(br_out_instr_struct_reg),
        // .MUL_in(mul_out_instr_struct_reg),
        // .DIV_in(div_out_instr_struct_reg),
        .MEM_in(mem_out_instr_struct_reg),
        // .BR_in('0),
        .MUL_in(mul_out_instr_struct_reg),
        .DIV_in(div_out_instr_struct_reg),

        .ALU_resp(alu_wb_resp),
        .MEM_resp(mem_wb_resp),
        .BR_resp(br_wb_resp),
        .MUL_resp(mul_wb_resp),
        .DIV_resp(div_wb_resp),

        .instr_out(wb_bus),

        .push_status(wb_push_status),
        .rob_addr(wb_rob_addr),
        .*
    );

    rob rob_i (
        .rst(br_rst),

        .push_instr(rd_rob_req),
        .data_entry(rd_rob_data_entry),
        .tail_addr(rd_rob_addr),
        .instr_resp(rd_rob_resp),

        .push_status(wb_push_status),
        .rob_addr(wb_rob_addr),

        .rob_pop_data(rob_pop_data),
        .pop_resp(rob_pop_resp),
        .br_mispredict(rob_br_mispredict),
        .*
    );

    cacheline_buffer line_buffer (
        .ufp_addr(imem_addr),
        .ufp_rmask(imem_rmask),
        .ufp_rdata(imem_rdata),
        .ufp_resp(imem_resp),

        .dfp_addr(buf_addr),
        .dfp_read(buf_read),
        .dfp_rdata(buf_rdata),
        .dfp_resp(buf_resp),
        
        .*
    );

    icache icache_i (
        .ufp_addr(buf_addr),
        .ufp_rmask(icache_rmask),
        .ufp_wmask(4'b0000),
        .ufp_rdata(buf_rdata),
        .ufp_wdata('x),
        .ufp_resp(buf_resp),

        .dfp_addr(icache_addr),
        .dfp_read(icache_read),
        .dfp_write(icache_write),
        .dfp_rdata(icache_rdata),
        .dfp_wdata(icache_wdata),
        .dfp_resp(icache_resp),

        .*
    );

    prefetcher prefetcher_i (
        .ufp_addr(icache_addr),
        .ufp_read(icache_read),
        .ufp_rdata(icache_rdata),
        .ufp_resp(icache_resp),

        .dfp_addr(pf_addr),
        .dfp_read(pf_read),
        .dfp_rdata(pf_rdata),
        .dfp_resp(pf_resp),
        
        .*
    );

    cache dcache_i (
        .ufp_addr(dmem_addr),
        .ufp_rmask(dcache_rmask),
        .ufp_wmask(dcache_wmask),
        .ufp_rdata(dmem_rdata),
        .ufp_wdata(dmem_wdata),
        .ufp_resp(dmem_resp),

        .dfp_addr(dcache_addr),
        .dfp_read(dcache_read),
        .dfp_write(dcache_write),
        .dfp_rdata(dcache_rdata),
        .dfp_wdata(dcache_wdata),
        .dfp_resp(dcache_resp),
        .*
    );

    arbiter_2 arbiter_i (
        .icache_addr(pf_addr),
        .icache_read(pf_read),
        .icache_rdata(pf_rdata),
        .icache_resp(pf_resp),

        .*
    );

    cacheline_adapter cache_adapter (       // need to change signals after adding arbiter
        .dfp_addr(adapter_addr),
        .dfp_read(adapter_read),
        .dfp_write(adapter_write),
        .dfp_wdata(adapter_wdata),
        .dfp_rdata(adapter_rdata),
        .dfp_resp(adapter_resp),    

        .*
    );

    prf #(
        .PHYS_REG_BITS(PHYS_REG_BITS)
    ) prf_i (
        .rst(br_rst),

        .stall(rs_stall | ~rd_rob_resp),

        .regf_we(prf_regf_we),
        .valid_we(prf_valid_we),
        .rd_valid(prf_rd_valid),
        .rd_v(prf_rd_v),
        .rs1_s(prf_rs1_s),
        .rs2_s(prf_rs2_s),
        .rd_s(prf_rd_s),
        .commit_rd_s(prf_commit_rd_s),
        .rs1_v(prf_rs1_v),
        .rs2_v(prf_rs2_v),
        .rs1_valid(prf_rs1_valid),
        .rs2_valid(prf_rs2_valid),
        // .push(fl_push),
        .push(rob_pop_resp),
        .pop(fl_pop),
        .flush(fl_flush),
        .push_resp(fl_push_resp),
        .pop_resp(fl_pop_resp),
        .pop_data(fl_pop_data),
        .head(fl_head),
        .tail(fl_tail),
        .*
    );

    rat_arf #(
        .PHYS_REG_BITS(PHYS_REG_BITS)
    ) rat_arf_i (
        .rst(rst),
        .br_rst(rob_br_mispredict),
        .stall(rs_stall | ~rd_rob_resp),

        .we_rename(arf_we_rename),
        .we_paddr(arf_we_paddr),
        .rs1_s(arf_rs1_s),
        .rs2_s(arf_rs2_s),
        .rename_s(arf_rename_s),
        .paddr_s(arf_paddr_s),
        .rename_v(arf_rename_v),
        .paddr_v(arf_paddr_v),
        .rs1_valid(arf_rs1_valid),
        .rs2_valid(arf_rs2_valid),
        .rs1_data(arf_rs1_data),
        .rs2_data(arf_rs2_data),
        .rs1_renamed(arf_rs1_renamed),
        .rs2_renamed(arf_rs2_renamed),
        .rs1_paddr(arf_rs1_paddr),
        .rs2_paddr(arf_rs2_paddr),

        .we_rd_rename(arf_we_rd_rename),
        .we_rd_data(arf_we_rd_data),
        .rd_s(arf_rd_s),
        .rd_rename_v(arf_rd_rename_v),
        .rd_v(arf_rd_v),
        .rd_old_paddr(arf_rd_old_paddr),
        .*
    );

    logic               monitor_valid;
    logic   [63:0]      monitor_order;
    logic   [31:0]      monitor_inst;
    logic   [4:0]       monitor_rs1_addr;
    logic   [4:0]       monitor_rs2_addr;
    logic   [31:0]      monitor_rs1_rdata;
    logic   [31:0]      monitor_rs2_rdata;
    logic   [4:0]       monitor_rd_addr;
    logic   [31:0]      monitor_rd_wdata;
    logic   [31:0]      monitor_pc_rdata;
    logic   [31:0]      monitor_pc_wdata;
    logic   [31:0]      monitor_mem_addr;
    logic   [3:0]       monitor_mem_wmask;
    logic   [3:0]       monitor_mem_rmask;
    logic   [31:0]      monitor_mem_rdata;
    logic   [31:0]      monitor_mem_wdata;

    assign monitor_valid = monitor.valid;
    assign monitor_order = monitor.order;
    assign monitor_inst = monitor.inst;
    assign monitor_rs1_addr = monitor.rs1_addr;
    assign monitor_rs2_addr = monitor.rs2_addr;
    assign monitor_rs1_rdata = monitor.rs1_rdata;
    assign monitor_rs2_rdata = monitor.rs2_rdata;
    assign monitor_rd_addr = monitor.rd_addr;
    assign monitor_rd_wdata = monitor.rd_wdata;
    assign monitor_pc_rdata = monitor.pc_rdata;
    assign monitor_pc_wdata = monitor.pc_wdata;
    assign monitor_mem_addr = monitor.mem_addr;
    assign monitor_mem_wmask = monitor.mem_wmask;
    assign monitor_mem_rmask = monitor.mem_rmask;
    assign monitor_mem_rdata = monitor.mem_rdata;
    assign monitor_mem_wdata = monitor.mem_wdata;

endmodule : cpu
