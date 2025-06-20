// module top_tb;
    
//     // Waveform generation
//     initial begin
//         $fsdbDumpfile("dump.fsdb");
//         $fsdbDumpvars(0, "+all");
//     end

//     // Signals
//     logic           clk;
//     logic           rst;
    
//     // Cache-side signals
//     logic   [31:0]  dfp_addr;      
//     logic           dfp_read;   
//     logic           dfp_write;
//     logic   [255:0] dfp_wdata;   
//     logic   [255:0] dfp_rdata; 
//     logic           dfp_resp;   
    
//     // Memory-side signals
//     logic   [31:0]  bmem_addr;  
//     logic           bmem_read; 
//     logic           bmem_write;   
//     logic   [63:0]  bmem_wdata;   
//     logic   [63:0]  bmem_rdata;  
//     logic           bmem_rvalid;

//     // Generate a clock
//     initial clk = 1'b1;
//     always #1ns clk = ~clk;

//     // Reset task
//     task reset;
//         begin
//             rst = 1'b1;
//             dfp_addr = '0;
//             dfp_read = 1'b0;
//             dfp_write = 1'b0;
//             dfp_wdata = '0;
//             bmem_rdata = '0;
//             bmem_rvalid = 1'b0;
            
//             repeat (2) @(posedge clk);
//             rst <= 1'b0;
//         end
//     endtask

//     // Instantiating cacheline_adapter
//     cacheline_adapter dut(
//         .clk        (clk),
//         .rst        (rst),
//         .dfp_addr   (dfp_addr),
//         .dfp_read   (dfp_read),
//         .dfp_write  (dfp_write),
//         .dfp_wdata  (dfp_wdata),
//         .dfp_rdata  (dfp_rdata),
//         .dfp_resp   (dfp_resp),
//         .bmem_addr  (bmem_addr),
//         .bmem_read  (bmem_read),
//         .bmem_write (bmem_write),
//         .bmem_wdata (bmem_wdata),
//         .bmem_rdata (bmem_rdata),
//         .bmem_rvalid(bmem_rvalid)
//     );
    
    
//     // Cache Clean Miss (Read) Test
//     task test_clean_miss;
//         begin
//             $display("Starting Clean Miss (Read) Test");
            
//             // Set initial values
//             dfp_addr = 32'h1000_0000;
//             dfp_read = 1'b1;
//             dfp_write = 1'b0;
//             bmem_rdata = 'x;
//             bmem_rvalid = '0;
            
//             // Wait a cycle for adapter to respond
//             repeat (1) @(posedge clk);
            
//             // Cache can deassert signals after initiating
//             dfp_read = 1'b0;
//             dfp_addr = '0;

//             // Wait a cycle for DFP to respond
//             repeat (1) @(posedge clk);
            
//             // Send first burst
//             bmem_rdata = 64'hDEAD_BEEF_DEAD_0001;
//             bmem_rvalid = '1;
//             repeat (1) @(posedge clk);
            
//             // Send second burst
//             bmem_rdata = 64'hDEAD_BEEF_DEAD_0002;
//             bmem_rvalid = '1;
//             repeat (1) @(posedge clk);
            
//             // Send third burst
//             bmem_rdata = 64'hDEAD_BEEF_DEAD_0003;
//             bmem_rvalid = '1;
//             repeat (1) @(posedge clk);
            
//             // Send fourth burst
//             bmem_rdata = 64'hDEAD_BEEF_DEAD_0004;
//             bmem_rvalid = '1;
//             repeat (1) @(posedge clk);
            
//             // Check if resp is raised and data is available
//             if (dfp_resp !== 1'b1)
//                 $display("Error: dfp_resp not asserted after 4th burst!");
                
//             $display("Expected rdata: %h", {64'hDEAD_BEEF_DEAD_0004, 
//                                            64'hDEAD_BEEF_DEAD_0003, 
//                                            64'hDEAD_BEEF_DEAD_0002, 
//                                            64'hDEAD_BEEF_DEAD_0001});
//             $display("Actual rdata:   %h", dfp_rdata);
            
//             // End burst sequence
//             bmem_rvalid = '0;
//             bmem_rdata = 'x;
//             repeat (2) @(posedge clk);
            
//             $display("Clean Miss Test Complete");
//         end
//     endtask
    
//     // Cache Dirty Miss (Write) Test
//     task test_dirty_miss;
//         begin
//             $display("Starting Dirty Miss (Write) Test");
            
//             // Set initial values
//             dfp_addr = 32'h2000_0000;
//             dfp_write = 1'b1;
//             dfp_read = 1'b0;
//             dfp_wdata = {64'h8888_8888_8888_8888, 
//                          64'h7777_7777_7777_7777, 
//                          64'h6666_6666_6666_6666, 
//                          64'h5555_5555_5555_5555};
            
//             // Wait a cycle for adapter to respond
//             repeat (1) @(posedge clk);
            
//             // Check first burst
//             $display("First burst wdata: %h", bmem_wdata);
//             if (bmem_wdata !== 64'h5555_5555_5555_5555)
//                 $display("Error: First bmem_wdata incorrect!");
            
//             // Second burst
//             repeat (1) @(posedge clk);
//             $display("Second burst wdata: %h", bmem_wdata);
//             if (bmem_wdata !== 64'h6666_6666_6666_6666)
//                 $display("Error: Second bmem_wdata incorrect!");
            
//             // Third burst
//             repeat (1) @(posedge clk);
//             $display("Third burst wdata: %h", bmem_wdata);
//             if (bmem_wdata !== 64'h7777_7777_7777_7777)
//                 $display("Error: Third bmem_wdata incorrect!");
            
//             // Fourth burst
//             repeat (1) @(posedge clk);
//             $display("Fourth burst wdata: %h", bmem_wdata);
//             if (bmem_wdata !== 64'h8888_8888_8888_8888)
//                 $display("Error: Fourth bmem_wdata incorrect!");
            
//             // Cache can deassert signals after completed
//             dfp_write = 1'b0;
//             dfp_addr = '0;
//             dfp_wdata = '0;

//             // Check response
//             repeat (1) @(posedge clk);
//             if (dfp_resp !== 1'b1)
//                 $display("Error: dfp_resp not asserted after write complete!");
            
//             repeat (2) @(posedge clk);
            
//             $display("Dirty Miss Test Complete");
//         end
//     endtask

    
//     // Testing
//     initial begin
//         $display("Starting Cacheline Adapter Testbench");
        
//         // Reset the DUT
//         reset();
        
//         // Test the clean miss scenario
//         test_clean_miss();
        
//         // Add some delay between tests
//         repeat (3) @(posedge clk);
        
//         // Test the dirty miss scenario
//         test_dirty_miss();
        
//         // End simulation
//         repeat (10) @(posedge clk);
//         $display("Testbench complete");
//         $finish;
//     end

// endmodule : top_tb