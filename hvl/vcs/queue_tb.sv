module queue_tb;

    timeunit 1ps;
    timeprecision 1ps;

    // initial begin
    //     $fsdbDumpfile("dump.fsdb");
    //     $fsdbDumpvars(0, "+all");
    // end

    int clock_half_period_ps;
    initial begin
        $value$plusargs("CLOCK_PERIOD_PS_ECE411=%d", clock_half_period_ps);
        clock_half_period_ps = clock_half_period_ps / 2;
    end

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;
    bit rst;

    // define input parameters and DUT
    localparam  IN_WIDTH = 8;
    localparam  IN_BITS = 2;
    localparam  DEPTH = 2**IN_BITS;

    bit push, pop, push_resp, pop_resp;
    logic [IN_WIDTH-1:0] push_data, pop_data;
    bit full, empty;

    queue #(
        .WIDTH(IN_WIDTH),
        .NUM_BITS(IN_BITS) 
    ) dut (
        .clk0(clk),
        .rst0(rst),
        .push(push),
        .pop(pop),
        .push_data(push_data),
        .full(full),
        .empty(empty),
        .pop_data(pop_data),
        .push_resp(push_resp),
        .pop_resp(pop_resp)
    );

    typedef struct packed {
        bit     push;               // perform a push
        bit     pop;                // perform a pop
        logic   [IN_WIDTH-1:0]push_data;    // data to push to queue

        bit     transaction_type;    // generate transaction type (0 - push ; 1 - pop)
    } input_transaction_t;

    typedef struct packed {
        bit     full;               // queue is full
        bit     empty;              // queue is empty
        logic   [IN_WIDTH-1:0]pop_data;     // data popped from queue
        bit     push_resp;
        bit     pop_resp;
    } output_transaction_t;

    // Golden Model Queue
    logic   [IN_WIDTH-1:0]  golden_queue[DEPTH-1:0];
    logic   [IN_BITS:0]     golden_head, golden_tail;
    logic                   golden_full, golden_empty;

    function input_transaction_t generate_input_transaction(bit random, bit push);
        input_transaction_t inp;
        bit trans_type;
        logic [IN_WIDTH-1:0]data;

        // std::randomize(trans_type);     // randomize a push or pop instruction
        trans_type = push;
        // specify push/pop (comment out randomize)
        // trans_type = '0;     // always push
        // trans_type = '1;     // always pop
        std::randomize(data);

        if(random) begin
            if(trans_type) begin
                inp.push = '0;
                inp.pop = '1;
                inp.push_data = 'x;
            end else begin
                inp.push = '1;
                inp.pop = '0;
                inp.push_data = data;
            end
        end else begin
            // for simultaneous push/pop (comment out if-statement)
            inp.push = '1;
            inp.pop = '1;
            inp.push_data = data;
        end
        inp.transaction_type = trans_type;
        return inp;

    endfunction : generate_input_transaction

    function output_transaction_t golden_queue_do(input_transaction_t inp);
        output_transaction_t out;
        out.pop_data = 'x;
        out.push_resp = '0;
        out.pop_resp = '0;

        if(inp.pop) begin
            if(!golden_empty) begin
                out.pop_data = golden_queue[golden_head[IN_BITS-1:0]];
                golden_head = golden_head + 1'b1;
                out.pop_resp = '1;
            end
        end

        if(inp.push) begin
            if(!golden_full) begin
                golden_queue[golden_tail[IN_BITS-1:0]] = inp.push_data;
                golden_tail = golden_tail + 1'b1;
                out.push_resp = '1;
            end
        end

        out.full = (golden_head[IN_BITS] != golden_tail[IN_BITS]
                && golden_head[IN_BITS-1:0] == golden_tail[IN_BITS-1:0]);
        out.empty = (golden_head[IN_BITS] == golden_tail[IN_BITS]
                && golden_head[IN_BITS-1:0] == golden_tail[IN_BITS-1:0]);

        golden_full = out.full;
        golden_empty = out.empty;

        return out;

    endfunction : golden_queue_do

    task drive_dut(input input_transaction_t inp, output output_transaction_t out);
        push <= inp.push;
        pop <= inp.pop;
        push_data <= inp.push_data;

        @(posedge clk);
        out.full = full;
        out.empty = empty;
        out.pop_data = pop_data;
        out.pop_resp = pop_resp;
        out.push_resp = push_resp;
    endtask : drive_dut

    function compare_outputs(output_transaction_t golden_out, output_transaction_t dut_out);
        // if(golden_out.full != dut_out.full) begin
        //     $error("MISMATCHED FULL STATUS");
        // end

        // if(golden_out.empty != dut_out.empty) begin
        //     $error("MISMATCHED EMPTY STATUS");
        // end

        // if(golden_out.pop_data != dut_out.pop_data) begin
        //     $error("MISMATCHED POP DATA");
        // end

        // if(golden_out.pop_resp != dut_out.pop_resp) begin
        //     $error("MISMATCHED POP ERRORS");
        // end

        // if(golden_out.push_resp != dut_out.push_resp) begin
        //     $error("MISMATCHED PUSH ERRORS");
        // end

    endfunction : compare_outputs

    initial begin
        input_transaction_t inp;
        output_transaction_t golden_out;
        output_transaction_t dut_out;

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

        golden_queue = '{default: '0};
        golden_head = '0;
        golden_tail = '0;
        golden_full = '0;
        golden_empty = '1;

        // simultaneous push/pop test
        repeat (10) begin
            inp = generate_input_transaction(0, 0);
            golden_out = golden_queue_do(inp);
            drive_dut(inp, dut_out);

            compare_outputs(dut_out, golden_out);
        end

        // fill the queue with pushes
        repeat (DEPTH + 1) begin
            inp = generate_input_transaction(1, 0);
            golden_out = golden_queue_do(inp);
            drive_dut(inp, dut_out);

            compare_outputs(dut_out, golden_out);
        end

        // empty the queue with pops
        repeat (DEPTH + 1) begin
            inp = generate_input_transaction(1, 1);
            golden_out = golden_queue_do(inp);
            drive_dut(inp, dut_out);

            compare_outputs(dut_out, golden_out);
        end            

        $finish;
    end

endmodule : queue_tb
