module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;
    bit rst;

    initial begin
        $fsdbDumpfile("dump.fsdb");
        if ($test$plusargs("NO_DUMP_ALL_ECE411")) begin
            $fsdbDumpvars(0, dut, "+all");
            $fsdbDumpoff();
        end else begin
            $fsdbDumpvars(0, "+all");
        end
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;

        // repeat (150) @(posedge clk);
        // $finish;
    end

    `include "top_tb.svh"

    // cacheline_buffer dut (
    //     .*
    // );

    // typedef struct packed {
    //     logic   [31:0]      ufp_addr;
    //     logic   [3:0]       ufp_rmask;

    //     logic   [255:0]     dfp_rdata;
    //     // logic               dfp_resp;

    //     bit                 hit;
    // } linebuf_input_transaction_t;

    // typedef struct packed {
    //     logic   [31:0]      ufp_rdata;

    //     logic   [31:0]      dfp_addr;
    //     logic               dfp_read;
    // } linebuf_output_transaction_t;

    // logic   [255:0]     golden_data;
    // logic   [26:0]      golden_tag;


    // function linebuf_input_transaction_t generate_linebuf_input_transaction(bit start);
    //     linebuf_input_transaction_t inp;

    //     logic   [31:0]  addr;
    //     // logic   [3:0]   rmask;
    //     logic   [255:0] rdata;
    //     // logic   [2:0]   addr_offset;

    //     bit hit;

    //     inp.ufp_rmask = 4'b1111;

    //     std::randomize(hit);

    //     if (hit && ~start) begin    // can only hit if line not empty
    //         // addr[31:5] = golden_tag;
    //         // std::randomize(addr[4:2]);   
    //         // addr[1:0] = 2'b00;    
    //         std::randomize(addr) with {addr[31:5] == golden_tag &&
    //                                     addr[1:0] == 2'b00;}; 

    //         rdata = 'x;
    //         // std::randomize(rdata);

    //         inp.ufp_addr = addr;
    //         inp.dfp_rdata = rdata;
    //         inp.hit = 1'b1;
    //     end
    //     else begin
    //         std::randomize(addr) with {addr > 32'hAAAAA000;};
    //         addr[1:0] = 2'b00;

    //         std::randomize(rdata);

    //         inp.ufp_addr = addr;
    //         inp.dfp_rdata = rdata;
    //         inp.hit = 1'b0;
    //     end

    //     return inp;
    // endfunction: generate_linebuf_input_transaction

    // function linebuf_output_transaction_t linebuf_golden_model_do(linebuf_input_transaction_t inp);
    //     linebuf_output_transaction_t out;
        
    //     if (inp.ufp_addr[31:5] == golden_tag) begin
    //         out.ufp_rdata = golden_data[(inp.ufp_addr[4:2] * 32) +: 32];

    //         out.dfp_addr = 'x;
    //         out.dfp_read = 1'b0;
    //     end/ if (imem_resp & ~dmem_stall) begin
        //     pc_next = pc + 'd4;
        //     order_next = order + 'd1;
        // end
        // if (~dmem_stall) begin
        //     // if (ex_mm_reg_next.ctrl_word.br_en && ex_mm_reg_next.ctrl_word.branch_inst) begin
        //     if (branched) begin
        //         if (ex_mm_reg_next.ctrl_word.jalr) begin
        //             pc_next = alu_v & 32'hfffffffe;
        //         end
        //         else begin
        //             pc_next = alu_v;
        //         end
        //         // order_next = order - 'd1;
        //         order_next = ex_mm_reg_next.order + 'd1;
        //     end
        //     else if (imem_resp && ~id_ex_reg_next.ctrl_word.mm_bub && ~imem_discard) begin
        //         pc_next = pc + 'd4;
        //         orde
    //         out.dfp_read = 1'b1;
    //         out.dfp_addr = inp.ufp_addr;

    //         out.ufp_rdata = golden_data[(inp.ufp_addr[4:2] * 32) +: 32];
    //     end

    //     return out;
    // endfunction: linebuf_golden_model_do

    // task linebuf_drive_dut(input linebuf_input_transaction_t inp, output linebuf_output_transaction_t out);
    //     ufp_addr <= inp.ufp_addr;
    //     ufp_rmask <= inp.ufp_rmask;

    //     dfp_rdata <= inp.dfp_rdata;
    //     dfp_resp <= 1'b0;

    //     if (inp.hit) begin
    //         @(posedge clk iff(ufp_resp));
    //         out.ufp_rdata = ufp_rdata;
    //         out.dfp_addr = 'x;
    //         out.dfp_read = 1'b0;
    //     end
    //     else begin
    //         @(posedge clk iff (dfp_read));
    //         out.dfp_addr = dfp_addr;
    //         out.dfp_read = dfp_read;

    //         @(posedge clk);
    //         @(posedge clk);
    //         dfp_resp <= 1'b1;

    //         @(posedge clk iff (ufp_resp));
    //         dfp_resp <= 1'b0;

    //         out.ufp_rdata = ufp_rdata;
    //     end
    //     // @(posedge clk iff (dfp_read | ufp_resp));
    //     // if (dfp_read) begin
    //     //     @(posedge clk);
    //     //     @(posedge clk);
    //     //     dfp_resp <= 1'b1;

    //     //     out.dfp_addr = dfp_addr;
    //     //     out.dfp_read = dfp_read;
    //     // end
    // endtask: linebuf_drive_dut

    // function linebuf_compare_outputs(linebuf_output_transaction_t golden_out, linebuf_output_transaction_t dut_out);
    //     if (dut_out.ufp_rdata != golden_out.ufp_rdata) begin
    //         $error("DUT ufp_rdata incorrect");
    //     end
    //     // if (dut_out.dfp_addr != golden_out.dfp_addr && dut_out.dfp_read == golden_out.dfp_read) begin
    //     //     $error("DUT dfp addr incorrect");
    //     // end
    //     if (dut_out.dfp_read != golden_out.dfp_read) begin
    //         $error("DUT dfp read mismatch");
    //     end
    //     else if (dut_out.dfp_addr != golden_out.dfp_addr && golden_out.dfp_read) begin
    //         $error("DUT request incorrect dfp_addr");
    //     end
    // endfunction: linebuf_compare_outputs

    // `include "top_tb.svh"

    // initial begin
    //     linebuf_input_transaction_t inp;
    //     linebuf_output_transaction_t golden_out;
    //     linebuf_output_transaction_t dut_out;

    //     inp = generate_linebuf_input_transaction(1);

    //     golden_out = linebuf_golden_model_do(inp);
    //     linebuf_drive_dut(inp, dut_out);

    //     linebuf_compare_outputs(golden_out, dut_out);

    //     repeat (500) begin
    //         // golden_out = linebuf_golden_model_do(inp);

    //         inp = generate_linebuf_input_transaction(0);

    //         golden_out = linebuf_golden_model_do(inp);
    //         linebuf_drive_dut(inp, dut_out);

    //         linebuf_compare_outputs(golden_out, dut_out);
    //     end

    //     $finish;
    // end

endmodule : top_tb
