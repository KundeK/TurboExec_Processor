module wb 
import rv32i_types::*;
(
    input   logic   clk,
    input   logic   rst,
    
    // completed instructions from functional units
    input   ooo_instr_t     ALU_in,
    input   ooo_instr_t     MEM_in,
    input   ooo_instr_t     BR_in,
    input   ooo_instr_t     MUL_in,
    input   ooo_instr_t     DIV_in,
    
    // response to functional units to allow next instruction
    output  logic           ALU_resp,
    output  logic           MEM_resp,
    output  logic           BR_resp,
    output  logic           MUL_resp,
    output  logic           DIV_resp,

    // completed instruction broadcast to WB bus
    output  wb_bus_t        instr_out,
    output  ooo_instr_t     wb_instr_struct,
    // update the ROB status
    // input   logic           status_resp,

    output  logic           push_status,
    output  logic           [ROB_NUM_BITS-1:0]rob_addr       
);

    logic [2:0] counter;

    always_ff @(posedge clk) begin
        if(rst) begin
            counter <= '0;
        end else begin            
            counter <= (counter + 1'b1) % 3'b101;
        end
    end

    always_comb begin
        instr_out.valid = '0;        // instr_out.valid = 1'b0
        instr_out.rd_addr = 'x;
        instr_out.rd_paddr = 'x;
        instr_out.rd_data = 'x;
        
        push_status = '0;
        rob_addr = 'x;

        wb_instr_struct = '0;

        ALU_resp = '0;
        MEM_resp = '0;
        BR_resp = '0;
        MUL_resp = '0;
        DIV_resp = '0;
        //static priorities        
        if(MEM_in.valid) begin
            instr_out.valid = '1;
            instr_out.rd_addr = MEM_in.rd_addr;
            instr_out.rd_paddr = MEM_in.rd_paddr;
            instr_out.rd_data = MEM_in.rd_data;

            wb_instr_struct = MEM_in;

            push_status = '1;
            rob_addr = MEM_in.rob_addr;

            MEM_resp = '1;
        end else
        if (BR_in.valid) begin
            instr_out.valid = '1;
            instr_out.rd_addr = BR_in.rd_addr;
            instr_out.rd_paddr = BR_in.rd_paddr;
            instr_out.rd_data = BR_in.rd_data;
    
            wb_instr_struct = BR_in;
    
            push_status = '1;
            rob_addr = BR_in.rob_addr;
    
            BR_resp = '1;
        end else 
        if(MUL_in.valid) begin
            instr_out.valid = '1;
            instr_out.rd_addr = MUL_in.rd_addr;
            instr_out.rd_paddr = MUL_in.rd_paddr;
            instr_out.rd_data = MUL_in.rd_data;

            wb_instr_struct = MUL_in;

            push_status = '1;
            rob_addr = MUL_in.rob_addr;

            MUL_resp = '1;
        end else
        if(DIV_in.valid) begin
            instr_out.valid = '1;
            instr_out.rd_addr = DIV_in.rd_addr;
            instr_out.rd_paddr = DIV_in.rd_paddr;
            instr_out.rd_data = DIV_in.rd_data;

            wb_instr_struct = DIV_in;

            push_status = '1;
            rob_addr = DIV_in.rob_addr;

            DIV_resp = '1;
        end else
        if(ALU_in.valid) begin
            instr_out.valid = '1;
            instr_out.rd_addr = ALU_in.rd_addr;
            instr_out.rd_paddr = ALU_in.rd_paddr;
            instr_out.rd_data = ALU_in.rd_data;

            wb_instr_struct = ALU_in;

            push_status = '1;
            rob_addr = ALU_in.rob_addr;

            ALU_resp = '1;
        end


        // round robin priorities for functional units
//         case(counter)
//             3'b000 : begin
//                 if(ALU_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = ALU_in.rd_addr;
//                     instr_out.rd_paddr = ALU_in.rd_paddr;
//                     instr_out.rd_data = ALU_in.rd_data;

//                     wb_instr_struct = ALU_in;

//                     push_status = '1;
//                     rob_addr = ALU_in.rob_addr;

//                     ALU_resp = '1;
//                 end else 
//                 if(MEM_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MEM_in.rd_addr;
//                     instr_out.rd_paddr = MEM_in.rd_paddr;
//                     instr_out.rd_data = MEM_in.rd_data;

//                     wb_instr_struct = MEM_in;

//                     push_status = '1;
//                     rob_addr = MEM_in.rob_addr;

//                     MEM_resp = '1;
//                 end else 
//                 if (BR_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = BR_in.rd_addr;
//                     instr_out.rd_paddr = BR_in.rd_paddr;
//                     instr_out.rd_data = BR_in.rd_data;

//                     wb_instr_struct = BR_in;

//                     push_status = '1;
//                     rob_addr = BR_in.rob_addr;

//                     BR_resp = '1;
//                 end else 
//                 if(MUL_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MUL_in.rd_addr;
//                     instr_out.rd_paddr = MUL_in.rd_paddr;
//                     instr_out.rd_data = MUL_in.rd_data;

//                     wb_instr_struct = MUL_in;

//                     push_status = '1;
//                     rob_addr = MUL_in.rob_addr;

//                     MUL_resp = '1;
//                 end else
//                 if(DIV_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = DIV_in.rd_addr;
//                     instr_out.rd_paddr = DIV_in.rd_paddr;
//                     instr_out.rd_data = DIV_in.rd_data;

//                     wb_instr_struct = DIV_in;

//                     push_status = '1;
//                     rob_addr = DIV_in.rob_addr;

//                     DIV_resp = '1;
//                 end
//             end
//             3'b001 : begin
//                 if(MEM_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MEM_in.rd_addr;
//                     instr_out.rd_paddr = MEM_in.rd_paddr;
//                     instr_out.rd_data = MEM_in.rd_data;

//                     wb_instr_struct = MEM_in;

//                     push_status = '1;
//                     rob_addr = MEM_in.rob_addr;

//                     MEM_resp = '1;
//                 end else 
//                 if (BR_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = BR_in.rd_addr;
//                     instr_out.rd_paddr = BR_in.rd_paddr;
//                     instr_out.rd_data = BR_in.rd_data;

//                     wb_instr_struct = BR_in;

//                     push_status = '1;
//                     rob_addr = BR_in.rob_addr;

//                     BR_resp = '1;
//                 end else 
//                 if(MUL_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MUL_in.rd_addr;
//                     instr_out.rd_paddr = MUL_in.rd_paddr;
//                     instr_out.rd_data = MUL_in.rd_data;

//                     wb_instr_struct = MUL_in;

//                     push_status = '1;
//                     rob_addr = MUL_in.rob_addr;

//                     MUL_resp = '1;
//                 end else 
//                 if(DIV_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = DIV_in.rd_addr;
//                     instr_out.rd_paddr = DIV_in.rd_paddr;
//                     instr_out.rd_data = DIV_in.rd_data;

//                     wb_instr_struct = DIV_in;

//                     push_status = '1;
//                     rob_addr = DIV_in.rob_addr;

//                     DIV_resp = '1;
//                 end else 
//                 if(ALU_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = ALU_in.rd_addr;
//                     instr_out.rd_paddr = ALU_in.rd_paddr;
//                     instr_out.rd_data = ALU_in.rd_data;

//                     wb_instr_struct = ALU_in;

//                     push_status = '1;
//                     rob_addr = ALU_in.rob_addr;

//                     ALU_resp = '1;
//                 end
//             end
//             3'b010 : begin
//                 if (BR_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = BR_in.rd_addr;
//                     instr_out.rd_paddr = BR_in.rd_paddr;
//                     instr_out.rd_data = BR_in.rd_data;

//                     wb_instr_struct = BR_in;

//                     push_status = '1;
//                     rob_addr = BR_in.rob_addr;

//                     BR_resp = '1;
//                 end else 
//                 if(MUL_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MUL_in.rd_addr;
//                     instr_out.rd_paddr = MUL_in.rd_paddr;
//                     instr_out.rd_data = MUL_in.rd_data;

//                     wb_instr_struct = MUL_in;

//                     push_status = '1;
//                     rob_addr = MUL_in.rob_addr;

//                     MUL_resp = '1;
//                 end else 
//                 if(DIV_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = DIV_in.rd_addr;
//                     instr_out.rd_paddr = DIV_in.rd_paddr;
//                     instr_out.rd_data = DIV_in.rd_data;

//                     wb_instr_struct = DIV_in;

//                     push_status = '1;
//                     rob_addr = DIV_in.rob_addr;

//                     DIV_resp = '1;
//                 end else 
//                 if(ALU_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = ALU_in.rd_addr;
//                     instr_out.rd_paddr = ALU_in.rd_paddr;
//                     instr_out.rd_data = ALU_in.rd_data;

//                     wb_instr_struct = ALU_in;

//                     push_status = '1;
//                     rob_addr = ALU_in.rob_addr;

//                     ALU_resp = '1;
//                 end else 
//                 if(MEM_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MEM_in.rd_addr;
//                     instr_out.rd_paddr = MEM_in.rd_paddr;
//                     instr_out.rd_data = MEM_in.rd_data;

//                     wb_instr_struct = MEM_in;

//                     push_status = '1;
//                     rob_addr = MEM_in.rob_addr;

//                     MEM_resp = '1;
//                 end
//             end
//             3'b011 : begin
//                 if(MUL_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MUL_in.rd_addr;
//                     instr_out.rd_paddr = MUL_in.rd_paddr;
//                     instr_out.rd_data = MUL_in.rd_data;

//                     wb_instr_struct = MUL_in;

//                     push_status = '1;
//                     rob_addr = MUL_in.rob_addr;

//                     MUL_resp = '1;
//                 end else 
//                 if(DIV_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = DIV_in.rd_addr;
//                     instr_out.rd_paddr = DIV_in.rd_paddr;
//                     instr_out.rd_data = DIV_in.rd_data;

//                     wb_instr_struct = DIV_in;

//                     push_status = '1;
//                     rob_addr = DIV_in.rob_addr;

//                     DIV_resp = '1;
//                 end else 
//                 if(ALU_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = ALU_in.rd_addr;
//                     instr_out.rd_paddr = ALU_in.rd_paddr;
//                     instr_out.rd_data = ALU_in.rd_data;

//                     wb_instr_struct = ALU_in;

//                     push_status = '1;
//                     rob_addr = ALU_in.rob_addr;

//                     ALU_resp = '1;
//                 end else 
//                 if(MEM_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MEM_in.rd_addr;
//                     instr_out.rd_paddr = MEM_in.rd_paddr;
//                     instr_out.rd_data = MEM_in.rd_data;

//                     wb_instr_struct = MEM_in;

//                     push_status = '1;
//                     rob_addr = MEM_in.rob_addr;

//                     MEM_resp = '1;
//                 end else 
//                 if (BR_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = BR_in.rd_addr;
//                     instr_out.rd_paddr = BR_in.rd_paddr;
//                     instr_out.rd_data = BR_in.rd_data;

//                     wb_instr_struct = BR_in;

//                     push_status = '1;
//                     rob_addr = BR_in.rob_addr;

//                     BR_resp = '1;
//                 end
//             end
//             3'b100 : begin
//                 if(DIV_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = DIV_in.rd_addr;
//                     instr_out.rd_paddr = DIV_in.rd_paddr;
//                     instr_out.rd_data = DIV_in.rd_data;

//                     wb_instr_struct = DIV_in;

//                     push_status = '1;
//                     rob_addr = DIV_in.rob_addr;

//                     DIV_resp = '1;
//                 end else  
//                 if(ALU_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = ALU_in.rd_addr;
//                     instr_out.rd_paddr = ALU_in.rd_paddr;
//                     instr_out.rd_data = ALU_in.rd_data;

//                     wb_instr_struct = ALU_in;

//                     push_status = '1;
//                     rob_addr = ALU_in.rob_addr;

//                     ALU_resp = '1;
//                 end else 
//                 if(MEM_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MEM_in.rd_addr;
//                     instr_out.rd_paddr = MEM_in.rd_paddr;
//                     instr_out.rd_data = MEM_in.rd_data;

//                     wb_instr_struct = MEM_in;

//                     push_status = '1;
//                     rob_addr = MEM_in.rob_addr;

//                     MEM_resp = '1;
//                 end else 
//                 if (BR_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = BR_in.rd_addr;
//                     instr_out.rd_paddr = BR_in.rd_paddr;
//                     instr_out.rd_data = BR_in.rd_data;

//                     wb_instr_struct = BR_in;

//                     push_status = '1;
//                     rob_addr = BR_in.rob_addr;

//                     BR_resp = '1;
//                 end else 
//                 if(MUL_in.valid) begin
//                     instr_out.valid = '1;
//                     instr_out.rd_addr = MUL_in.rd_addr;
//                     instr_out.rd_paddr = MUL_in.rd_paddr;
//                     instr_out.rd_data = MUL_in.rd_data;

//                     wb_instr_struct = MUL_in;

//                     push_status = '1;
//                     rob_addr = MUL_in.rob_addr;

//                     MUL_resp = '1;
//                 end
//             end
//             default : ;
//         endcase
    end

endmodule : wb