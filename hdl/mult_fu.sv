module multiply_fu
import rv32i_types::*;
#(
    parameter PHYS_REG_BITS = 6,
    parameter NUM_STAGES = 4    
)
(
    input   logic               clk,
    input   logic               rst,
    
    // Reservation station interface
    input   logic               multiply_fu_ready,   // Instruction is ready to be executed
    input   ooo_instr_t         multiply_issue_instr, // Instruction from RS
    // input   ctrl_word_t         multiply_issue_ctrl_word, // Control word from RS
    
    // Writeback interface
    input   logic               MEM_resp,            // Writeback acknowledgment
    output  ooo_instr_t         MUL_out,             // Result to writeback
    
    // Status signals back to RS
    output  logic               multiply_fu_busy     // FU is currently processing an instruction
);
    
    // Pipeline stage registers
    // ooo_instr_t         instr_pipe[NUM_STAGES];
    // logic               valid_pipe[NUM_STAGES];

    ooo_instr_t         mul_instr;
    logic   [2:0]       stage_counter;
    
    logic [32:0]        a, b;
    logic [65:0]        product;
    
    logic signed    [32:0] as, bs;
    logic unsigned  [32:0] au, bu;

    logic               start_mult;
    logic               busy_internal;
    
    DW_mult_pipe #(
        .a_width(33),                 
        .b_width(33),                
        .num_stages(NUM_STAGES),      
        .stall_mode(0),             
        .rst_mode(1),                 
        .op_iso_mode(4)              
    ) mult_pipe (
        .clk(clk),                   
        .rst_n(~rst),              
        // .en(~busy_internal || MEM_resp), // Enable when not busy or when writeback acknowledges
        .en(1'b1),
        .tc(1'b1),                    // Two's complement (signed operation)
        .a(a),                        // Multiplicand
        .b(b),                        // Multiplier
        .product(product)            
    );
    
    // Busy logic
    always_ff @(posedge clk) begin
        if (rst) begin
            busy_internal <= 1'b0;
        end
        else begin
            // if (start_mult)
            if (multiply_issue_instr.valid) 
                busy_internal <= 1'b1;
            else if (MEM_resp)
                busy_internal <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            mul_instr <= '0;
            stage_counter <= '0;
        end
        else begin
            if (multiply_issue_instr.valid) begin
                mul_instr <= multiply_issue_instr;
                stage_counter <= stage_counter + 1'd1;
            end
            if (stage_counter != 3'd0) begin
                stage_counter <= stage_counter + 1'd1;
            end
            if (stage_counter == unsigned'(3'(NUM_STAGES-1))) begin
                stage_counter <= '0;
            end
        end
    end
    
    // Pipeline control and dataflow
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         for (integer unsigned i = 0; i < NUM_STAGES; i++) begin
    //             valid_pipe[i] <= 1'b0;
    //             instr_pipe[i] <= '0;
    //         end
    //     end
    //     else begin
    //         // Shift pipeline stages
    //         if (~busy_internal || MEM_resp) begin
    //             for (integer unsigned i = NUM_STAGES-1; i > 0; i--) begin
    //                 valid_pipe[i] <= valid_pipe[i-1];
    //                 instr_pipe[i] <= instr_pipe[i-1];
    //             end
                
    //             // First stage loading
    //             if (start_mult) begin
    //                 valid_pipe[0] <= 1'b1;
    //                 instr_pipe[0] <= multiply_issue_instr;
    //             end
    //             else begin
    //                 valid_pipe[0] <= 1'b0;
    //             end
    //         end
    //     end
    // end
    
    // Input handling
    always_comb begin
        // Default values
        // start_mult = multiply_fu_ready && !busy_internal;
        start_mult = multiply_issue_instr.valid;
        multiply_fu_busy = busy_internal | multiply_issue_instr.valid;
        
        // Operand preparation based on instruction type
        a = {1'b0, multiply_issue_instr.rs1_data};
        b = {1'b0, multiply_issue_instr.rs2_data};

        au = {1'b0, multiply_issue_instr.rs1_data};
        bu = {1'b0, multiply_issue_instr.rs2_data};

        as = signed'({multiply_issue_instr.rs1_data[31], multiply_issue_instr.rs1_data});  // signed
        bs = signed'({multiply_issue_instr.rs2_data[31], multiply_issue_instr.rs2_data});  // signed     
        
        if (multiply_fu_ready) begin
            unique case (multiply_issue_instr.data.r_type.funct3)
                3'b000: begin // MUL
                    a = {1'b0, multiply_issue_instr.rs1_data};  // unsigned for low bits
                    b = {1'b0, multiply_issue_instr.rs2_data}; 
                    // a = au;
                    // b = bu;
                end
                3'b001: begin // MULH
                    a = {multiply_issue_instr.rs1_data[31], multiply_issue_instr.rs1_data};  // signed
                    b = {multiply_issue_instr.rs2_data[31], multiply_issue_instr.rs2_data};  // signed
                    // a = as;
                    // b = bs;
                end
                3'b010: begin // MULHSU
                    a = {multiply_issue_instr.rs1_data[31], multiply_issue_instr.rs1_data};  // signed
                    b = {1'b0, multiply_issue_instr.rs2_data};  // unsigned
                    // a = as;
                    // b = bu;
                end
                3'b011: begin // MULHU
                    a = {1'b0, multiply_issue_instr.rs1_data};  // unsigned
                    b = {1'b0, multiply_issue_instr.rs2_data};  // unsigned
                    // a = au;
                    // b = bu;
                end
                default: begin
                    a = {1'b0, multiply_issue_instr.rs1_data};
                    b = {1'b0, multiply_issue_instr.rs2_data};
                    // a = au;
                    // b = bu;
                end
            endcase
        end
    end
    
    // Output result generation
    always_comb begin
        // Default output
        // MUL_out = instr_pipe[NUM_STAGES-1];
        // MUL_out.valid = valid_pipe[NUM_STAGES-1];
        // MUL_out = instr_pipe[0];
        MUL_out = '0;

        // Set result based on operation
        if (stage_counter == unsigned'(3'(NUM_STAGES-1))) begin
            MUL_out = mul_instr;
            unique case (mul_instr.data.r_type.funct3)
                3'b000: begin // MUL
                    MUL_out.rd_data = product[31:0];  // Lower 32 bits
                end
                3'b001: begin // MULH
                    MUL_out.rd_data = product[63:32]; // Upper 32 bits
                end
                3'b010: begin // MULHSU
                    MUL_out.rd_data = product[63:32]; // Upper 32 bits
                end
                3'b011: begin // MULHU
                    MUL_out.rd_data = product[63:32]; // Upper 32 bits
                end
                default: begin
                    MUL_out.rd_data = product[31:0];
                end
            endcase
        end
    end

endmodule : multiply_fu