module divide_fu
import rv32i_types::*;
#(
    parameter PHYS_REG_BITS = 6,
    parameter NUM_STAGES = 4    
)
(
    input   logic               clk,
    input   logic               rst,
    
    // Reservation station interface
    input   logic               divide_fu_ready,   
    input   ooo_instr_t         divide_issue_instr, 
    // input   ctrl_word_t         divide_issue_ctrl_word, 
    
    // Writeback interface
    input   logic               FP_resp,            
    output  ooo_instr_t         DIV_out,            
    
    // Status signals back to RS
    output  logic               divide_fu_busy      // FU is currently processing an instruction
);

    // Internal signals
    logic [32:0]        a, b;          // Operands
    logic [32:0]        quotient;      
    logic [32:0]        remainder;    
    logic               divide_by_0;   
    // logic               div_start;   
    // logic               div_done;      
    logic               div_busy;      
    // ooo_instr_t         div_instr_reg; // Stored instruction
    // logic [2:0]         funct3_reg;    // Stored function code

    logic   [2:0]       stage_counter;
    ooo_instr_t         div_instr;

    logic signed    [32:0] as, bs;
    logic unsigned  [32:0] au, bu;
    
    DW_div_pipe #(
        .a_width(33),                
        .b_width(33),                
        .tc_mode(1),                 
        .rem_mode(1),                // Remainder mode (1=remainder, 0=modulus)
        .num_stages(NUM_STAGES),     
        .stall_mode(0),              
        .rst_mode(1),                // Asynchronous reset
        .op_iso_mode(4)              // Preferred isolation style
    ) div_pipe (
        .clk(clk),                 
        .rst_n(~rst),    
        .en(1'b1),            
        // .en(~div_busy || FP_resp),   // Enable when not busy or on acknowledge
        .a(a),                       // Dividend
        .b(b),                       // Divisor
        .quotient(quotient),         // Division result
        .remainder(remainder),       
        .divide_by_0(divide_by_0)    // Division by zero flag
    );
    
    // Control state machine
    always_ff @(posedge clk) begin
        if (rst) begin
            div_busy <= 1'b0;
            // div_instr_reg <= '0;
            // funct3_reg <= '0;

            // stage_counter <= '0;
        end
        else begin
            // if (div_start) begin
            if (divide_issue_instr.valid) begin
                div_busy <= 1'b1;
                // div_instr_reg <= divide_issue_instr;
                // funct3_reg <= divide_issue_instr.data.r_type.funct3;
            end
            else if (FP_resp) begin
                div_busy <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            stage_counter <= '0;
            div_instr <= '0;
        end
        else begin
            if (divide_issue_instr.valid) begin
                div_instr <= divide_issue_instr;
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
    
    // Generate done signal after NUM_STAGES cycles
    // logic [NUM_STAGES:0] done_shift_reg;
    
    // always_ff @(posedge clk) begin
    //     if (rst) begin
    //         done_shift_reg <= '0;
    //     end
    //     else if (~div_busy || FP_resp) begin
    //         done_shift_reg <= {done_shift_reg[NUM_STAGES-1:0], div_start};
    //     end
    // end
    
    // assign div_done = done_shift_reg[NUM_STAGES];
    // assign div_start = divide_fu_ready && !div_busy;
    assign divide_fu_busy = div_busy | divide_issue_instr.valid;
    
    // set based on function code for signed/unsigned
    always_comb begin
        // Default values
        // a = divide_issue_instr.rs1_data;
        // b = divide_issue_instr.rs2_data;
        a = {1'b0, divide_issue_instr.rs1_data};
        b = {1'b0, divide_issue_instr.rs2_data};

        au = {1'b0, divide_issue_instr.rs1_data};
        bu = {1'b0, divide_issue_instr.rs2_data};

        as = signed'({divide_issue_instr.rs1_data[31], divide_issue_instr.rs1_data});  // signed
        bs = signed'({divide_issue_instr.rs2_data[31], divide_issue_instr.rs2_data});  // unsigned

        
        if (divide_fu_ready) begin
            unique case (divide_issue_instr.data.r_type.funct3)
                3'b100: begin // MUL
                    a = {divide_issue_instr.rs1_data[31], divide_issue_instr.rs1_data};  // unsigned for low bits
                    b = {divide_issue_instr.rs2_data[31], divide_issue_instr.rs2_data}; 
                    // a = as;
                    // b = bs;
                end
                3'b101: begin // MULH
                    a = {1'b0, divide_issue_instr.rs1_data};  // signed
                    b = {1'b0, divide_issue_instr.rs2_data};  // signed
                    // a = au;
                    // b = bu;
                end
                3'b110: begin // MULHSU
                    a = {divide_issue_instr.rs1_data[31], divide_issue_instr.rs1_data};  // signed
                    b = {divide_issue_instr.rs2_data[31], divide_issue_instr.rs2_data};  // unsigned
                    // a = as;
                    // b = bs;
                end
                3'b111: begin // MULHU
                    a = {1'b0, divide_issue_instr.rs1_data};  // unsigned
                    b = {1'b0, divide_issue_instr.rs2_data};  // unsigned
                    // a = au;
                    // b = bu;
                end
                default: begin
                    a = {1'b0, divide_issue_instr.rs1_data};
                    b = {1'b0, divide_issue_instr.rs2_data};
                    // a = au;
                    // b = bu;
                end
            endcase
        end

    end
    
    // Output result
    always_comb begin
        // DIV_out = div_instr_reg;
        // DIV_out.valid = div_done;
        DIV_out = '0;

        if (stage_counter == unsigned'(3'(NUM_STAGES-1))) begin
            DIV_out = div_instr;
            case (div_instr.data.r_type.funct3)
                3'b100: // DIV - signed division
                    if (divide_by_0) begin
                        DIV_out.rd_data = 32'hffffffff;
                    end
                    else
                    DIV_out.rd_data = quotient[31:0];
                
                3'b101: // DIVU - unsigned division
                    if (divide_by_0) begin
                        DIV_out.rd_data = 32'hffffffff;
                    end
                    else
                    DIV_out.rd_data = quotient[31:0];
                
                3'b110: // REM - signed remainder
                    if (divide_by_0) begin
                        DIV_out.rd_data = div_instr.rs1_data;
                    end
                    else
                    DIV_out.rd_data = remainder[31:0];
                
                3'b111: // REMU - unsigned remainder
                    if (divide_by_0) begin
                        DIV_out.rd_data = div_instr.rs1_data;
                    end
                    else
                    DIV_out.rd_data = remainder[31:0];
                
                default:
                    DIV_out.rd_data = '0;
            endcase
        end
    end

endmodule : divide_fu