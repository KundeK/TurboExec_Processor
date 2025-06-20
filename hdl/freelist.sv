module freelist #(
    parameter               PHYS_REG_BITS = 6
)(
    input   logic           clk,
    input   logic           rst,
    
    input   logic           push,
    input   logic           pop,

    input   logic           flush,

    output  logic           push_resp,
    output  logic           pop_resp,
    output  logic   [PHYS_REG_BITS-1:0] pop_data,
    output  logic   [PHYS_REG_BITS-1:0] head, tail
);

//  pop to allocate, push to free
//  pop advances head, push advances tail
//  push signal comes when commit sees PRF_head ~valid & status==ready

    logic   [PHYS_REG_BITS:0]   prf_head, prf_tail;
    logic                       full, empty;

    assign full = prf_head[PHYS_REG_BITS] != prf_tail[PHYS_REG_BITS]
                    && prf_head[PHYS_REG_BITS-1:0] == prf_tail[PHYS_REG_BITS-1:0];
    assign empty = prf_head[PHYS_REG_BITS] == prf_tail[PHYS_REG_BITS]
                    && prf_head[PHYS_REG_BITS-1:0] == prf_tail[PHYS_REG_BITS-1:0];
    assign head = prf_head[PHYS_REG_BITS-1:0];
    assign tail = prf_tail[PHYS_REG_BITS-1:0];


    always_ff @(posedge clk) begin
        if (rst | flush) begin
            //  set full on reset or flush
            // prf_head[PHYS_REG_BITS] <= ~prf_tail[PHYS_REG_BITS];
            // prf_head[PHYS_REG_BITS-1:0] <= prf_tail[PHYS_REG_BITS-1:0];
            prf_head <= {(PHYS_REG_BITS+1){1'b0}};
            prf_tail <= {{1'b1}, {(PHYS_REG_BITS){1'b0}}};

            push_resp <= 1'b0;
        end
        else begin
            if (pop) begin
                if (!empty) begin
                    prf_head[PHYS_REG_BITS:0] <= prf_head[PHYS_REG_BITS:0] + 1'b1;
                end
            end
            if (push) begin
                if (!full) begin
                    prf_tail[PHYS_REG_BITS:0] <= prf_tail[PHYS_REG_BITS:0] + 1'b1;
                    push_resp <= 1'b1;
                end
            end
        end
    end

    always_comb begin
        pop_data = 'x;
        pop_resp = 1'b0;

        if (pop) begin
            if (!empty) begin
                pop_resp = 1'b1;
                pop_data = prf_head[PHYS_REG_BITS-1:0];
            end
        end
    end

endmodule : freelist