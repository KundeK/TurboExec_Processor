module queue #(
    parameter       WIDTH = 32,
    parameter       NUM_BITS = 3
)(
    input   logic   clk0,
    input   logic   rst0,

    input   logic   push,
    input   logic   pop,
    input   logic   [WIDTH-1:0]push_data,

    output  logic   full,
    output  logic   empty,
    output  logic   [WIDTH-1:0]pop_data,
    output  logic   pop_resp,
    output  logic   push_resp
);

    localparam              DEPTH = 2**NUM_BITS;
    logic   [WIDTH-1:0]     internal_queue[DEPTH];    
    logic   [NUM_BITS:0]    head_reg, tail_reg;
    
    assign  full = (head_reg[NUM_BITS] != tail_reg[NUM_BITS]
                        && head_reg[NUM_BITS-1:0] == tail_reg[NUM_BITS-1:0]);
    assign  empty = (head_reg[NUM_BITS] == tail_reg[NUM_BITS]
                        && head_reg[NUM_BITS-1:0] == tail_reg[NUM_BITS-1:0]);


     always_ff @(posedge clk0) begin
        if (rst0) begin
            for (integer i = 0; i < DEPTH; i++) begin
                internal_queue[i] <= '0;
            end
            head_reg <= '0;
            tail_reg <= '0;
            push_resp <= '0;
            // pop_resp <= '0;
        end else begin
            // pop_data <= 'x;
            push_resp <= '0;
            // pop_resp <= '0;
            if(pop) begin
                if(!empty) begin
                    // pop_data <= internal_queue[head_reg[NUM_BITS-1:0]];
                    head_reg[NUM_BITS:0] <= head_reg[NUM_BITS:0] + 1'b1;
                    // pop_resp <= '1;
                end
            end
            if(push) begin
                if(!full) begin
                    internal_queue[tail_reg[NUM_BITS-1:0]] <= push_data;
                    tail_reg[NUM_BITS:0] <= tail_reg[NUM_BITS:0] + 1'b1;
                    push_resp <= '1;
                end
            end
        end
    end

    always_comb begin
        pop_data = 'x;
        pop_resp = '0;
        if(pop) begin
            if(!empty) begin
                pop_data = internal_queue[head_reg[NUM_BITS-1:0]];
                pop_resp = '1;
            end
        end
    end

endmodule : queue
