module reservation_station
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    
    // Dispatch interface
    input   logic           dispatch_valid,
    input   ooo_instr_t     dispatch_instr,    // Instruction from dispatch stage
    input   ctrl_word_t     dispatch_ctrl_word, // Control word from dispatch stage
    
    // Common Data Bus interface from writeback
    input   wb_bus_t        wb_bus,            // Writeback bus containing completed instruction info
    
    // Functional Unit status
    input   logic           add_fu_busy,     // ADD FU is busy
    input   logic           multiply_fu_busy, // MUL FU is busy
    input   logic           divide_fu_busy,  // DIV FU is busy
    input   logic           mem_fu_busy,
    input   logic           br_fu_busy, // BR FU is busy
    
    output  logic           add_full,       
    output  logic           multiply_full,
    output  logic           divide_full,
    output  logic           mem_full,
    
    output  logic           br_full,     
    output  logic           rs_stall,        // Any RS is full, stall dispatch
    
    output  logic           add_fu_ready,    
    output  logic           multiply_fu_ready, 
    output  logic           divide_fu_ready,
    output  logic           mem_fu_ready,
    output  logic           br_fu_ready, 

    input   ooo_instr_t     rob_head_instr,

    // Issue instr reqs
    input   logic           add_issue_req,
    input   logic           mul_issue_req,
    input   logic           div_issue_req,
    input   logic           mem_issue_req,
    input   logic           br_issue_req,
    
    // Issued instructions
    output  ooo_instr_t     add_issue_instr,
    output  ooo_instr_t     multiply_issue_instr, 
    output  ooo_instr_t     divide_issue_instr,  
    output  ooo_instr_t     mem_issue_instr,

    output  ooo_instr_t     br_issue_instr,
    
    // Issued control words
    output  ctrl_word_t     add_issue_ctrl_word,
    output  ctrl_word_t     multiply_issue_ctrl_word, 
    output  ctrl_word_t     divide_issue_ctrl_word,
    output  ctrl_word_t     mem_issue_ctrl_word,
    output  ctrl_word_t     br_issue_ctrl_word  
);

    // Parameters
    localparam NUM_ADD_BITS = 3;
    localparam NUM_MULTIPLY_BITS = 2;
    localparam NUM_DIVIDE_BITS = 2;
    localparam NUM_MEM_BITS = 4;
    localparam NUM_BRANCH_BITS = 3;

    localparam NUM_ADD_ENTRIES = 2**NUM_ADD_BITS;      // Number of ADD RS entries
    localparam NUM_MULTIPLY_ENTRIES = 2**NUM_MULTIPLY_BITS; // Number of MUL RS entries
    localparam NUM_DIVIDE_ENTRIES = 2**NUM_DIVIDE_BITS;   // Number of DIV RS entries
    localparam NUM_MEM_ENTRIES = 2**NUM_MEM_BITS;
    localparam NUM_BRANCH_ENTRIES = 2**NUM_BRANCH_BITS;   // Number of BR RS entries

    // Combined entry with instruction and control word
    typedef struct packed {
        ooo_instr_t instr;     
        ctrl_word_t ctrl_word;  
        logic       valid;    
    } rs_entry_t;

    // Reservation station arrays
    rs_entry_t add_rs[NUM_ADD_ENTRIES];
    rs_entry_t multiply_rs[NUM_MULTIPLY_ENTRIES];
    rs_entry_t divide_rs[NUM_DIVIDE_ENTRIES];
    rs_entry_t mem_rs[NUM_MEM_ENTRIES];
    rs_entry_t br_rs[NUM_BRANCH_ENTRIES];

    // queue #(
    //     .WIDTH($bits(ooo_instr_t) + $bits(ctrl_word_t)),
    //     .NUM_BITS(NUM_MEM_BITS)
    // ) mem_rs (
    //     .clk0(clk),
    //     .rst0(rst),

    //     .push(mem_do_dispatch),
    //     // .pop(mem_issue_req),
    //     .pop(mem_do_issue),
    //     .push_data({dispatch_instr, dispatch_ctrl_word}),

    //     .full(mem_full),
    //     .empty(mem_rs_empty),
    //     .pop_data({mem_issue_instr, mem_issue_ctrl_word}),
    //     .pop_resp(mem_rs_pop_resp),
    //     .push_resp(mem_rs_push_resp)
    // );

    // Control signals and indices
    logic add_do_dispatch, multiply_do_dispatch, divide_do_dispatch, mem_do_dispatch, br_do_dispatch;
    logic add_do_issue, multiply_do_issue, divide_do_issue, mem_do_issue, br_do_issue;
    logic wb_dispatched_rs1, wb_dispatched_rs2;
    logic [$clog2(NUM_ADD_ENTRIES)-1:0] add_free_idx, add_issue_idx;
    logic [$clog2(NUM_MULTIPLY_ENTRIES)-1:0] multiply_free_idx, multiply_issue_idx;
    logic [$clog2(NUM_DIVIDE_ENTRIES)-1:0] divide_free_idx, divide_issue_idx;
    logic [$clog2(NUM_BRANCH_ENTRIES)-1:0] br_free_idx, br_issue_idx;

    logic [$clog2(NUM_MEM_ENTRIES):0] mem_head, mem_tail;
    logic                             mem_rs_full, mem_rs_empty;

    assign mem_rs_full = mem_head[NUM_MEM_BITS] != mem_tail[NUM_MEM_BITS]
                    && mem_head[NUM_MEM_BITS-1:0] == mem_tail[NUM_MEM_BITS-1:0];
    assign mem_rs_empty = mem_head == mem_tail;

    assign mem_full = mem_rs_full;

    
    // wb_bus_t wb_bus_reg;
    
    // Register writeback signals for proper timing
    // always_ff @(posedge clk) begin
    //     if (rst)
    //         wb_bus_reg <= '0;
    //     else
    //         wb_bus_reg <= wb_bus;
    // end

    // Main RS logic
    always_ff @(posedge clk) begin
        if (rst) begin
            // Reset all reservation station entries
            for (integer unsigned i = 0; i < NUM_ADD_ENTRIES; i++)
                add_rs[i].valid <= 1'b0;
                
            for (integer unsigned i = 0; i < NUM_MULTIPLY_ENTRIES; i++)
                multiply_rs[i].valid <= 1'b0;
                
            for (integer unsigned i = 0; i < NUM_DIVIDE_ENTRIES; i++)
                divide_rs[i].valid <= 1'b0;

            for (integer unsigned i = 0; i < NUM_MEM_ENTRIES; i++)
                mem_rs[i].valid <= 1'b0;
            for (integer unsigned i = 0; i < NUM_BRANCH_ENTRIES; i++)
                br_rs[i].valid <= 1'b0;

            mem_head <= '0;
            mem_tail <= '0;
        end
        else begin
            // Dispatch new instructions
            if (add_do_dispatch) begin
                add_rs[add_free_idx].instr <= dispatch_instr;
                add_rs[add_free_idx].ctrl_word <= dispatch_ctrl_word;
                add_rs[add_free_idx].valid <= 1'b1;

                if (wb_dispatched_rs1) begin
                    add_rs[add_free_idx].instr.rs1_data <= wb_bus.rd_data;
                    add_rs[add_free_idx].instr.rs1_rdy <= 1'b1;
                end
                if (wb_dispatched_rs2) begin
                    add_rs[add_free_idx].instr.rs2_data <= wb_bus.rd_data;
                    add_rs[add_free_idx].instr.rs2_rdy <= 1'b1;
                end
            end
            
            if (multiply_do_dispatch) begin
                multiply_rs[multiply_free_idx].instr <= dispatch_instr;
                multiply_rs[multiply_free_idx].ctrl_word <= dispatch_ctrl_word;
                multiply_rs[multiply_free_idx].valid <= 1'b1;

                if (wb_dispatched_rs1) begin
                    multiply_rs[multiply_free_idx].instr.rs1_data <= wb_bus.rd_data;
                    multiply_rs[multiply_free_idx].instr.rs1_rdy <= 1'b1;
                end
                if (wb_dispatched_rs2) begin
                    multiply_rs[multiply_free_idx].instr.rs2_data <= wb_bus.rd_data;
                    multiply_rs[multiply_free_idx].instr.rs2_rdy <= 1'b1;
                end
            end
            
            if (divide_do_dispatch) begin
                divide_rs[divide_free_idx].instr <= dispatch_instr;
                divide_rs[divide_free_idx].ctrl_word <= dispatch_ctrl_word;
                divide_rs[divide_free_idx].valid <= 1'b1;

                if (wb_dispatched_rs1) begin
                    divide_rs[divide_free_idx].instr.rs1_data <= wb_bus.rd_data;
                    divide_rs[divide_free_idx].instr.rs1_rdy <= 1'b1;
                end
                if (wb_dispatched_rs2) begin
                    divide_rs[divide_free_idx].instr.rs2_data <= wb_bus.rd_data;
                    divide_rs[divide_free_idx].instr.rs2_rdy <= 1'b1;
                end
            end

            if (mem_do_dispatch) begin
                if (~mem_rs_full) begin
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].instr <= dispatch_instr;
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].ctrl_word <= dispatch_ctrl_word;
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].valid <= 1'b1;

                    mem_tail <= mem_tail + 1'b1;
                end

                if (wb_dispatched_rs1) begin
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].instr.rs1_data <= wb_bus.rd_data;
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].instr.rs1_rdy <= 1'b1;
                end
                if (wb_dispatched_rs2) begin
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].instr.rs2_data <= wb_bus.rd_data;
                    mem_rs[mem_tail[NUM_MEM_BITS-1:0]].instr.rs2_rdy <= 1'b1;
                end
            end
            
            if (br_do_dispatch) begin
                br_rs[br_free_idx].instr <= dispatch_instr;
                br_rs[br_free_idx].ctrl_word <= dispatch_ctrl_word;
                br_rs[br_free_idx].valid <= 1'b1;

                if (wb_dispatched_rs1) begin
                    br_rs[br_free_idx].instr.rs1_data <= wb_bus.rd_data;
                    br_rs[br_free_idx].instr.rs1_rdy <= 1'b1;
                end
                if (wb_dispatched_rs2) begin
                    br_rs[br_free_idx].instr.rs2_data <= wb_bus.rd_data;
                    br_rs[br_free_idx].instr.rs2_rdy <= 1'b1;
                end
            end
            
            // Clear entries when issued to functional units
            if (add_do_issue)
                add_rs[add_issue_idx].valid <= 1'b0;
            
            if (multiply_do_issue)
                multiply_rs[multiply_issue_idx].valid <= 1'b0;
            
            if (divide_do_issue)
                divide_rs[divide_issue_idx].valid <= 1'b0;

            if (mem_do_issue) begin
                mem_rs[mem_head[NUM_MEM_BITS-1:0]].valid <= 1'b0;
                mem_head <= mem_head + 1'b1;
            end

            if (br_do_issue)
                br_rs[br_issue_idx].valid <= 1'b0;
            
            // Process writeback
            if (wb_bus.valid) begin
                // Wake up operands in all reservation stations in parallel
                for (integer unsigned i = 0; i < NUM_ADD_ENTRIES; i++) begin
                    if (add_rs[i].valid) begin
                        // Check if operands match the writeback physical register
                        if (!add_rs[i].instr.rs1_rdy && add_rs[i].instr.rs1_used && 
                            add_rs[i].instr.rs1_paddr == wb_bus.rd_paddr) begin
                                add_rs[i].instr.rs1_rdy <= 1'b1;
                                add_rs[i].instr.rs1_data <= wb_bus.rd_data;
                        end

                        if (!add_rs[i].instr.rs2_rdy && add_rs[i].instr.rs2_used && 
                            add_rs[i].instr.rs2_paddr == wb_bus.rd_paddr) begin
                                add_rs[i].instr.rs2_rdy <= 1'b1;
                                add_rs[i].instr.rs2_data <= wb_bus.rd_data;
                        end
                    end
                end
                
                for (integer unsigned i = 0; i < NUM_MULTIPLY_ENTRIES; i++) begin
                    if (multiply_rs[i].valid) begin
                        if (!multiply_rs[i].instr.rs1_rdy && multiply_rs[i].instr.rs1_used && 
                            multiply_rs[i].instr.rs1_paddr == wb_bus.rd_paddr) begin
                                multiply_rs[i].instr.rs1_rdy <= 1'b1;
                                multiply_rs[i].instr.rs1_data <= wb_bus.rd_data;
                        end
                        if (!multiply_rs[i].instr.rs2_rdy && multiply_rs[i].instr.rs2_used && 
                            multiply_rs[i].instr.rs2_paddr == wb_bus.rd_paddr) begin
                                multiply_rs[i].instr.rs2_rdy <= 1'b1;
                                multiply_rs[i].instr.rs2_data <= wb_bus.rd_data;
                        end
                    end
                end
                
                for (integer unsigned i = 0; i < NUM_DIVIDE_ENTRIES; i++) begin
                    if (divide_rs[i].valid) begin
                        if (!divide_rs[i].instr.rs1_rdy && divide_rs[i].instr.rs1_used && 
                            divide_rs[i].instr.rs1_paddr == wb_bus.rd_paddr) begin
                                divide_rs[i].instr.rs1_rdy <= 1'b1;
                                divide_rs[i].instr.rs1_data <= wb_bus.rd_data;
                        end
                        if (!divide_rs[i].instr.rs2_rdy && divide_rs[i].instr.rs2_used && 
                            divide_rs[i].instr.rs2_paddr == wb_bus.rd_paddr) begin
                                divide_rs[i].instr.rs2_rdy <= 1'b1;
                                divide_rs[i].instr.rs2_data <= wb_bus.rd_data;
                        end
                    end
                end

                for (integer unsigned i = 0; i < NUM_MEM_ENTRIES; i++) begin
                    if (mem_rs[i].valid) begin
                        if (!mem_rs[i].instr.rs1_rdy && mem_rs[i].instr.rs1_used && 
                            mem_rs[i].instr.rs1_paddr == wb_bus.rd_paddr) begin
                                mem_rs[i].instr.rs1_rdy <= 1'b1;
                                mem_rs[i].instr.rs1_data <= wb_bus.rd_data;
                        end
                        if (!mem_rs[i].instr.rs2_rdy && mem_rs[i].instr.rs2_used && 
                            mem_rs[i].instr.rs2_paddr == wb_bus.rd_paddr) begin
                                mem_rs[i].instr.rs2_rdy <= 1'b1;
                                mem_rs[i].instr.rs2_data <= wb_bus.rd_data;
                        end
                    end
                end
                for (integer unsigned i = 0; i < NUM_BRANCH_ENTRIES; i++) begin
                    if (br_rs[i].valid) begin
                        if (!br_rs[i].instr.rs1_rdy && br_rs[i].instr.rs1_used && 
                            br_rs[i].instr.rs1_paddr == wb_bus.rd_paddr) begin
                                br_rs[i].instr.rs1_rdy <= 1'b1;
                                br_rs[i].instr.rs1_data <= wb_bus.rd_data;
                        end
                        if (!br_rs[i].instr.rs2_rdy && br_rs[i].instr.rs2_used && 
                            br_rs[i].instr.rs2_paddr == wb_bus.rd_paddr) begin
                                br_rs[i].instr.rs2_rdy <= 1'b1;
                                br_rs[i].instr.rs2_data <= wb_bus.rd_data;
                        end
                    end
                end

            end
        end
    end

    // Dispatch logic
    always_comb begin
        // Default values
        add_do_dispatch = 1'b0;
        multiply_do_dispatch = 1'b0;
        divide_do_dispatch = 1'b0;
        mem_do_dispatch = 1'b0;
        br_do_dispatch = 1'b0;
        
        add_free_idx = '0;
        multiply_free_idx = '0;
        divide_free_idx = '0;
        br_free_idx = '0;

        wb_dispatched_rs1 = 1'b0;
        wb_dispatched_rs2 = 1'b0;

        // Find first free entry in each RS
        for (integer unsigned i = 0; i < NUM_ADD_ENTRIES; i++) begin
            if (!add_rs[i].valid) begin
                add_free_idx = (NUM_ADD_BITS)'(i);
                break;
            end
        end
        
        for (integer unsigned i = 0; i < NUM_MULTIPLY_ENTRIES; i++) begin
            if (!multiply_rs[i].valid) begin
                multiply_free_idx = (NUM_MULTIPLY_BITS)'(i);
                break;
            end
        end
        
        for (integer unsigned i = 0; i < NUM_DIVIDE_ENTRIES; i++) begin
            if (!divide_rs[i].valid) begin
                divide_free_idx = (NUM_DIVIDE_BITS)'(i);
                break;
            end
        end
        
        for (integer unsigned i = 0; i < NUM_BRANCH_ENTRIES; i++) begin
            if (!br_rs[i].valid) begin
                br_free_idx = (NUM_BRANCH_BITS)'(i);
                break;
            end
        end

        // Dispatch based on instruction type if valid
        if (dispatch_valid) begin
            case (dispatch_instr.instr_type)
                alu: begin
                    if (!add_full) add_do_dispatch = 1'b1;
                end
                
                mult: begin
                    if (!multiply_full) multiply_do_dispatch = 1'b1;
                end
                
                div: begin
                    if (!divide_full) divide_do_dispatch = 1'b1;
                end

                mem: begin
                    if (!mem_full) mem_do_dispatch = 1'b1;
                end
                br: begin
                    if (!br_full) br_do_dispatch = 1'b1;
                end
                
                default: begin
                    
                end
            endcase
        end

        if (dispatch_valid) begin
            // check if our dispatched instr rs1 is on the wb_bus
            if (dispatch_instr.rs1_used && ~dispatch_instr.rs1_rdy && 
                wb_bus.valid && dispatch_instr.rs1_paddr == wb_bus.rd_paddr) begin
                    wb_dispatched_rs1 = 1'b1;
            end

            // check if our dispatched instr rs2 is on the wb_bus
            if (dispatch_instr.rs2_used && ~dispatch_instr.rs2_rdy && 
                wb_bus.valid && dispatch_instr.rs2_paddr == wb_bus.rd_paddr) begin
                    wb_dispatched_rs2 = 1'b1;
            end            
        end
    end

    // Issue logic
    always_comb begin
        // Default values
        add_do_issue = 1'b0;
        multiply_do_issue = 1'b0;
        divide_do_issue = 1'b0;
        mem_do_issue = 1'b0;
        br_do_issue = 1'b0;
        
        add_issue_idx = '0;
        multiply_issue_idx = '0;
        divide_issue_idx = '0;
        br_issue_idx = '0;

        add_fu_ready = 1'b0;
        multiply_fu_ready = 1'b0;
        divide_fu_ready = 1'b0;
        mem_fu_ready = 1'b0;
        br_fu_ready = 1'b0;
        
        add_issue_instr = '0;
        multiply_issue_instr = '0;
        divide_issue_instr = '0;
        mem_issue_instr = '0;
        br_issue_instr = '0;
        
        add_issue_ctrl_word = '0;
        multiply_issue_ctrl_word = '0;
        divide_issue_ctrl_word = '0;
        mem_issue_ctrl_word = '0;
        br_issue_ctrl_word = '0;
        

        // Find oldest ready instructions
        if (add_issue_req) begin
            for (integer unsigned i = 0; i < NUM_ADD_ENTRIES; i++) begin
                if (add_rs[i].valid && ~(add_rs[i].instr.rs1_used & ~add_rs[i].instr.rs1_rdy)
                        && ~(add_rs[i].instr.rs2_used & ~add_rs[i].instr.rs2_rdy) && !add_fu_busy) begin
                    add_issue_idx = (NUM_ADD_BITS)'(i);
                    add_do_issue = 1'b1;
                    add_fu_ready = 1'b1;
                    add_issue_instr = add_rs[i].instr;
                    add_issue_ctrl_word = add_rs[i].ctrl_word;
                    break;
                end
            end
        end

        if (mul_issue_req) begin
            for (integer unsigned i = 0; i < NUM_MULTIPLY_ENTRIES; i++) begin
                if (multiply_rs[i].valid && ~(multiply_rs[i].instr.rs1_used & ~multiply_rs[i].instr.rs1_rdy) 
                        && ~(multiply_rs[i].instr.rs2_used & ~multiply_rs[i].instr.rs2_rdy) && !multiply_fu_busy) begin
                    multiply_issue_idx = (NUM_MULTIPLY_BITS)'(i);
                    multiply_do_issue = 1'b1;
                    multiply_fu_ready = 1'b1;
                    multiply_issue_instr = multiply_rs[i].instr;
                    multiply_issue_ctrl_word = multiply_rs[i].ctrl_word;
                    break;
                end
            end
        end
        
        if (div_issue_req) begin
            for (integer unsigned i = 0; i < NUM_DIVIDE_ENTRIES; i++) begin
                if (divide_rs[i].valid && ~(divide_rs[i].instr.rs1_used & ~divide_rs[i].instr.rs1_rdy) 
                        && ~(divide_rs[i].instr.rs2_used & ~divide_rs[i].instr.rs2_rdy) && !divide_fu_busy) begin
                    divide_issue_idx = (NUM_DIVIDE_BITS)'(i);
                    divide_do_issue = 1'b1;
                    divide_fu_ready = 1'b1;
                    divide_issue_instr = divide_rs[i].instr;
                    divide_issue_ctrl_word = divide_rs[i].ctrl_word;
                    break;
                end
            end
        end

        if (mem_issue_req) begin
            if (~mem_rs_empty && mem_rs[mem_head[NUM_MEM_BITS-1:0]].valid && 
                ~(mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr.rs1_used & ~mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr.rs1_rdy) 
                && ~(mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr.rs2_used & ~mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr.rs2_rdy)
                && !mem_fu_busy && rob_head_instr.order == mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr.order) begin
                    mem_do_issue = 1'b1;
                    mem_fu_ready = 1'b1;
                    mem_issue_instr = mem_rs[mem_head[NUM_MEM_BITS-1:0]].instr;
                    mem_issue_ctrl_word = mem_rs[mem_head[NUM_MEM_BITS-1:0]].ctrl_word;
            end
        end
        
        if (br_issue_req) begin
            for (integer unsigned i = 0; i < NUM_BRANCH_ENTRIES; i++) begin
                if (br_rs[i].valid && ~(br_rs[i].instr.rs1_used & ~br_rs[i].instr.rs1_rdy) 
                        && ~(br_rs[i].instr.rs2_used & ~br_rs[i].instr.rs2_rdy) && !br_fu_busy) begin
                    br_issue_idx = (NUM_BRANCH_BITS)'(i);
                    br_do_issue = 1'b1;
                    br_fu_ready = 1'b1;
                    br_issue_instr = br_rs[i].instr;
                    br_issue_ctrl_word = br_rs[i].ctrl_word;
                    break;
                end
            end
        end
    end

    // Status logic
    always_comb begin
        // Check if any reservation station full
        add_full = 1'b1;
        multiply_full = 1'b1;
        divide_full = 1'b1;
        br_full = 1'b1;
        
        // Check for free entries in RS's
        for (integer unsigned i = 0; i < NUM_ADD_ENTRIES; i++) begin
            if (!add_rs[i].valid) begin
                add_full = 1'b0;
                break;
            end
        end
        
        for (integer unsigned i = 0; i < NUM_MULTIPLY_ENTRIES; i++) begin
            if (!multiply_rs[i].valid) begin
                multiply_full = 1'b0;
                break;
            end
        end
        
        for (integer unsigned i = 0; i < NUM_DIVIDE_ENTRIES; i++) begin
            if (!divide_rs[i].valid) begin
                divide_full = 1'b0;
                break;
            end
        end

        for (integer unsigned i = 0; i < NUM_BRANCH_ENTRIES; i++) begin
            if (!br_rs[i].valid) begin
                br_full = 1'b0;
                break;
            end
        end
        
        // Generate stall signal based on instruction type and RS fullness
        rs_stall = 1'b0;
        if (dispatch_valid) begin
            case (dispatch_instr.instr_type)
                alu:    rs_stall = add_full;
                mult:   rs_stall = multiply_full;
                div:    rs_stall = divide_full;
                mem:    rs_stall = mem_full;
                br:     rs_stall = br_full;
                default: rs_stall = 1'b0; 
            endcase
        end
    end

endmodule : reservation_station