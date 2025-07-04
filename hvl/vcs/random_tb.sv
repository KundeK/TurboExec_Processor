//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types::*;
(
    mem_itf_banked.mem itf
);

    initial itf.rvalid = 1'b0;
    initial itf.ready = 1'b1;

    `include "randinst.svh"

    RandInst gen = new();
    RandInst gen1 = new();

    // Do a bunch of LUIs to get useful register state.
    task init_register_state();
        for (int i = 0; i < 8; ++i) begin
            @(posedge itf.clk iff |itf.read);
            for (int j = 0; j < 4; ++j) begin
                if (j % 2 == 0) begin
                    gen.randomize() with {
                        instr.j_type.opcode == op_b_lui;
                        instr.j_type.rd == j[5:1];
                    };
                    gen1.randomize() with {
                        instr.j_type.opcode == op_b_lui;
                        instr.j_type.rd == j[5:1];
                    };
                end else begin
                    gen.randomize() with {
                        instr.i_type.opcode == op_b_imm;
                        instr.i_type.rs1 == j[5:1];
                        instr.i_type.funct3 == arith_f3_add;
                        instr.i_type.rd == j[5:1];
                    };
                    gen1.randomize() with {
                        instr.i_type.opcode == op_b_imm;
                        instr.i_type.rs1 == j[5:1];
                        instr.i_type.funct3 == arith_f3_add;
                        instr.i_type.rd == j[5:1];
                    };
                end

                // Your code here: package these memory interactions into a task.
                itf.raddr <= itf.addr;
                itf.rdata <= {gen.instr.word, gen1.instr.word};
                itf.rvalid <= 1'b1;
                @(posedge itf.clk);
                // @(posedge itf.clk) itf.resp[0] <= 1'b0;
            end
            itf.rvalid <= 1'b0;
        end
    endtask : init_register_state

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();
        repeat (5000) begin
            @(posedge itf.clk iff (|itf.read || |itf.write));

            // Always read out a valid instruction.
            if (|itf.read) begin
                for(int i = 0; i < 4; ++i) begin
                    gen.randomize() with {
                        instr.j_type.opcode inside {op_b_lui, op_b_imm, op_b_reg};
                        instr.j_type.rd != 5'b00000;
                    };
                    gen1.randomize() with {
                        instr.j_type.opcode inside {op_b_lui, op_b_imm, op_b_reg};
                        instr.j_type.rd != 5'b00000;
                    };
                    itf.raddr <= itf.addr;
                    itf.rdata <= {gen.instr.word, gen1.instr.word};
                    itf.rvalid <= 1'b1;
                    @(posedge itf.clk);
                end
                itf.rvalid <= 1'b0;
            end

            // If it's a write, do nothing and just respond.
            // itf.resp[0] <= 1'b1;
            // @(posedge itf.clk) itf.resp[0] <= 1'b0;
        end
    endtask : run_random_instrs

    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read) || $isunknown(itf.write)) begin
            $error("Memory Error: mask containes 1'bx");
            itf.error <= 1'b1;
        end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            // if (itf.addr[0][0] != 1'b0) begin
            //     $error("Memory Error: Address is not 16-bit aligned");
            //     itf.error <= 1'b1;
            // end
        end
    end

    // A single initial block ensures random stability.
    initial begin

        // Wait for reset.
        @(posedge itf.clk iff itf.rst == 1'b0);

        // Get some useful state into the processor by loading in a bunch of state.
        init_register_state();

        // Run!
        run_random_instrs();

        // Finish up
        $display("Random testbench finished!");
        $finish;
    end

endmodule : random_tb
