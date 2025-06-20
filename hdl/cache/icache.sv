module icache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    // output  logic   [31:0]  ufp_rdata,
    output  logic   [255:0] ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    // define states
    enum integer unsigned {
            s_idle,
            s_comp,
            s_alloc,
            s_wb
    } state, state_next;
    
    enum logic [1:0] {
        idle = 2'b00,
        hit  = 2'b01,
        clean_miss = 2'b10,
        dirty_miss = 2'b11
    } compare_result;

    logic   [31:0]  ufp_addr_reg;
    logic   [3:0]   ufp_rmask_reg;
    logic   [3:0]   ufp_wmask_reg;
    logic   [31:0]  ufp_wdata_reg;

    // active low
    logic                   csb[3:0];               //  shared all arrays in way

    // active low
    logic                   cache_data_web[3:0];    //  shared all arrays in way
    logic                   cache_tag_web[3:0];
    logic                   cache_valid_web[3:0];
    logic                   cache_dirty_web[3:0];

    logic       [31:0]      cache_data_wmask[3:0];  //  each way has diff mask

    // logic       [3:0]       cache_addr[3:0];        //
    logic       [3:0]       cache_addr;             //  all ways use same addr

    logic       [255:0]     cache_data_din[3:0];
    logic       [22:0]      cache_tag_din[3:0];
    logic                   cache_valid_din[3:0];
    logic                   cache_dirty_din[3:0];

    logic       [255:0]     cache_data_dout[3:0];
    logic       [22:0]      cache_tag_dout[3:0];
    logic                   cache_valid_dout[3:0];
    logic                   cache_dirty_dout[3:0];


    logic                   lru_csb;
    logic                   lru_web;
    // logic       [3:0]       lru_addr;
    logic       [2:0]       lru_din;
    logic       [2:0]       lru_dout;

    logic       [1:0]       lru_select;
    logic       [2:0]       lru_next;


            // assign      cache_addr = ufp_addr[8:5];


    logic       [1:0]       tag_select;
    // logic       [1:0]       tag_select_reg;
    logic                   tag_match;
    // logic                   tag_match_reg;

    // logic       [1:0]       lru_way_select;
    logic       [1:0]       cache_way_select;

    logic       [31:0]      cache_rdata;

    logic                   line_valid;
    logic                   line_dirty;

    logic       [255:0]     ufp_wdata_out_0;
    logic       [255:0]     ufp_wdata_out_1;
    logic       [255:0]     ufp_wdata_out_2;
    logic       [255:0]     ufp_wdata_out_3;

    logic       [31:0]      ufp_wdata_wmask_0;
    logic       [31:0]      ufp_wdata_wmask_1;
    logic       [31:0]      ufp_wdata_wmask_2;
    logic       [31:0]      ufp_wdata_wmask_3;

    // logic                   valid_select;
    // logic                   valid_match;

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (csb[i]),
            .web0       (cache_data_web[i]),
            .wmask0     (cache_data_wmask[i]),
            .addr0      (cache_addr),
            .din0       (cache_data_din[i]),
            .dout0      (cache_data_dout[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (csb[i]),
            .web0       (cache_tag_web[i]),
            .addr0      (cache_addr),
            .din0       (cache_tag_din[i]),
            .dout0      (cache_tag_dout[i])
        );
        sp_ff_array valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (csb[i]),
            .web0       (cache_valid_web[i]),
            .addr0      (cache_addr),
            .din0       (cache_valid_din[i]),
            .dout0      (cache_valid_dout[i])
        );
        sp_ff_array dirty_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (csb[i]),
            .web0       (cache_dirty_web[i]),
            .addr0      (cache_addr),
            .din0       (cache_dirty_din[i]),
            .dout0      (cache_dirty_dout[i])
        );
    end endgenerate

    sp_ff_array #(
        .WIDTH      (3)
    ) lru_array (
        .clk0       (clk),
        .rst0       (rst),
        .csb0       (lru_csb),
        .web0       (lru_web),
        .addr0      (cache_addr),
        .din0       (lru_din),
        .dout0      (lru_dout)
    );

    tag_array_compare tag_comparator (
        .tag(ufp_addr_reg[31:9]),

        .cache_tag0(cache_tag_dout[0]),
        .cache_tag1(cache_tag_dout[1]),
        .cache_tag2(cache_tag_dout[2]),
        .cache_tag3(cache_tag_dout[3]),

        .cache_valid_0(cache_valid_dout[0]),
        .cache_valid_1(cache_valid_dout[1]),
        .cache_valid_2(cache_valid_dout[2]),
        .cache_valid_3(cache_valid_dout[3]),

        .tag_select(tag_select),
        .tag_match(tag_match)
    );

    // select correct cacheline, output word to rdata
    // ufp_rdata_mux ufp_rdata_mux (
    //     .cacheline_0(cache_data_dout[0]),
    //     .cacheline_1(cache_data_dout[1]),
    //     .cacheline_2(cache_data_dout[2]),
    //     .cacheline_3(cache_data_dout[3]),

    //     .line_select(tag_select),           // use tag comparator to select
    //     // .line_select(cache_way_select),

    //     .offset(ufp_addr_reg[4:0]),
    //     .rmask(ufp_rmask_reg),

    //     .cache_rdata(ufp_rdata)
    //     // .cache_rdata(cache_rdata)
    // );

    icache_rdata_mux icache_rdata_mux (
        .cacheline_0(cache_data_dout[0]),
        .cacheline_1(cache_data_dout[1]),
        .cacheline_2(cache_data_dout[2]),
        .cacheline_3(cache_data_dout[3]),

        .line_select(tag_select),           // use tag comparator to select

        .cache_rdata(ufp_rdata)
    );

    bit_select_mux valid_mux (
        .cache_bit0(cache_valid_dout[0]),
        .cache_bit1(cache_valid_dout[1]),
        .cache_bit2(cache_valid_dout[2]),
        .cache_bit3(cache_valid_dout[3]),

        .bit_select(tag_select),
        // .bit_select(lru_select),
        // .bit_select(cache_way_select),

        .out_bit(line_valid)
    );

    bit_select_mux dirty_mux (
        .cache_bit0(cache_dirty_dout[0]),
        .cache_bit1(cache_dirty_dout[1]),
        .cache_bit2(cache_dirty_dout[2]),
        .cache_bit3(cache_dirty_dout[3]),

        // .bit_select(tag_select),
        .bit_select(lru_select),

        .out_bit(line_dirty)
    );

    ufp_wdata_demux wdata_demux (
        .wdata(ufp_wdata_reg),
        .wmask(ufp_wmask_reg),
        .offset(ufp_addr_reg[4:0]),

        .line_select(tag_select),
        // .line_select(cache_way_select),

        // .cacheline_0(cache_data_din[0]),
        // .cacheline_1(cache_data_din[1]),
        // .cacheline_2(cache_data_din[2]),
        // .cacheline_3(cache_data_din[3]),
        .cacheline_0(ufp_wdata_out_0),
        .cacheline_1(ufp_wdata_out_1),
        .cacheline_2(ufp_wdata_out_2),
        .cacheline_3(ufp_wdata_out_3),

        // .cache_wmask_0(cache_data_wmask[0]),
        // .cache_wmask_1(cache_data_wmask[1]),
        // .cache_wmask_2(cache_data_wmask[2]),
        // .cache_wmask_3(cache_data_wmask[3])
        .cache_wmask_0(ufp_wdata_wmask_0),
        .cache_wmask_1(ufp_wdata_wmask_1),
        .cache_wmask_2(ufp_wdata_wmask_2),
        .cache_wmask_3(ufp_wdata_wmask_3)
    );

    always_comb begin
        unique casez (lru_dout)
            3'b00?: begin
                lru_select = 2'b00;
                // lru_next = lru_dout ^ 3'b110;
            end
            3'b01?: begin
                lru_select = 2'b01;
                // lru_next = lru_dout ^ 3'b110;
            end
            3'b1?0: begin
                lru_select = 2'b10;
                // lru_next = lru_dout ^ 3'b101;
            end
            3'b1?1: begin
                lru_select = 2'b11;
                // lru_next = lru_dout ^ 3'b101;
            end
            default: begin
                lru_select = 2'b00;
                // lru_next = lru_dout ^ 3'b110;
            end
        endcase
    end

    // always_comb begin
    //     unique casez(tag_select)
    //         3'b00?: begin
    //             lru_next = tag_select ^ 3'b110;
    //         end
    //         3'b01?: begin
    //             lru_next = tag_select ^ 3'b110;
    //         end
    //         3'b1?0: begin
    //             lru_next = tag_select ^ 3'b101;
    //         end
    //         3'b1?1: begin
    //             lru_next = tag_select ^ 3'b101;
    //         end
    //         default: begin
    //             lru_next = tag_select ^ 3'b110;
    //         end
    //     endcase
    // end
    always_comb begin
        unique casez(cache_way_select)
            2'b00: begin
                // lru_next = cache_way_select ^ 3'b110;
                // lru_next = lru_dout ^ 3'b110;
                lru_next = {{2'b11},{lru_dout[0]}};
            end
            2'b01: begin
                // lru_next = cache_way_select ^ 3'b110;
                // lru_next = lru_dout ^ 3'b110;
                lru_next = {{2'b10},{lru_dout[0]}};
            end
            2'b10: begin
                // lru_next = cache_way_select ^ 3'b101;
                // lru_next = lru_dout ^ 3'b101;
                lru_next = {{1'b0},{lru_dout[1]},{1'b1}};
            end
            2'b11: begin
                // lru_next = cache_way_select ^ 3'b101;
                // lru_next = lru_dout ^ 3'b101;
                lru_next = {{1'b0},{lru_dout[1]},{1'b0}};
            end
            default: begin
                // lru_next = cache_way_select ^ 3'b110;
                // lru_next = lru_dout ^ 3'b110;
                lru_next = {{2'b11},{lru_dout[0]}};
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= s_idle;

            ufp_addr_reg    <= '0;
            ufp_rmask_reg   <= '0;
            ufp_wmask_reg   <= '0;
            ufp_wdata_reg   <= '0;

            // tag_select_reg  <= 2'b0;
            // tag_match_reg   <= 1'b0;
        end
        else begin
            state <= state_next;

            if (state == s_idle) begin
                ufp_addr_reg    <= ufp_addr;
                ufp_rmask_reg   <= ufp_rmask;
                ufp_wmask_reg   <= ufp_wmask;
                ufp_wdata_reg   <= ufp_wdata;
            end
            // if (state == s_comp) begin
            //     tag_select_reg  <= tag_select;
            //     tag_match_reg   <= tag_match;
            // end
        end
    end

    always_comb begin
        state_next = state;

        cache_addr = ufp_addr_reg[8:5];

        ufp_resp = 1'b0;

        // csb = 'b1;
        // for (logic i = 2'b00; i < 2'b11; i++) begin
        //     csb[i] = 1'b1;

        //     cache_data_web[i] = 1'b1;
        //     cache_tag_web[i] = 1'b1;
        //     cache_valid_web[i] = 1'b1;
        //     cache_dirty_web[i] = 1'b1;

        //     cache_data_wmask[i] = 32'b0;

        //     cache_data_din[i] = 'b0;
        //     cache_tag_din[i] = 'b0;
        //     cache_valid_din[i] = 'b0;
        //     cache_dirty_din[i] = 'b0;
        // end
        csb[0] = 1'b1;

        cache_data_web[0] = 1'b1;
        cache_tag_web[0] = 1'b1;
        cache_valid_web[0] = 1'b1;
        cache_dirty_web[0] = 1'b1;

        cache_data_wmask[0] = 32'b0;

        cache_data_din[0] = 256'b0;
        cache_tag_din[0] = 23'b0;
        cache_valid_din[0] = 1'b0;
        cache_dirty_din[0] = 1'b0;

        csb[1] = 1'b1;

        cache_data_web[1] = 1'b1;
        cache_tag_web[1] = 1'b1;
        cache_valid_web[1] = 1'b1;
        cache_dirty_web[1] = 1'b1;

        cache_data_wmask[1] = 32'b0;

        cache_data_din[1] = 256'b0;
        cache_tag_din[1] = 23'b0;
        cache_valid_din[1] = 1'b0;
        cache_dirty_din[1] = 1'b0;

        csb[2] = 1'b1;

        cache_data_web[2] = 1'b1;
        cache_tag_web[2] = 1'b1;
        cache_valid_web[2] = 1'b1;
        cache_dirty_web[2] = 1'b1;

        cache_data_wmask[2] = 32'b0;

        cache_data_din[2] = 256'b0;
        cache_tag_din[2] = 23'b0;
        cache_valid_din[2] = 1'b0;
        cache_dirty_din[2] = 1'b0;

        csb[3] = 1'b1;

        cache_data_web[3] = 1'b1;
        cache_tag_web[3] = 1'b1;
        cache_valid_web[3] = 1'b1;
        cache_dirty_web[3] = 1'b1;

        cache_data_wmask[3] = 32'b0;

        cache_data_din[3] = 256'b0;
        cache_tag_din[3] = 23'b0;
        cache_valid_din[3] = 1'b0;
        cache_dirty_din[3] = 1'b0;

        // cache_data_web = 'b1;
        // cache_tag_web = 'b1;
        // cache_valid_web = 'b1;
        // cache_dirty_web = 'b1;

        // cache_data_wmask = 'x;

        dfp_addr = 32'b0;
        dfp_read = 1'b0;
        dfp_write = 1'b0;
        dfp_wdata = 256'b0;

        // cache_data_din = 'x;
        // cache_tag_din = 'x;
        // cache_valid_din = 'x;
        // cache_dirty_din = 'x;

        // cache_data_dout = ';
        // cache_tag_dout = 'b0;
        // cache_valid_dout = 'b0;
        // cache_dirty_dout = 'b0;

        lru_csb = 1'b1;
        lru_web = 1'b1;

        lru_din = 3'b000;
        // lru_dout = 'b0;

        compare_result = idle;

        cache_way_select = lru_select;
        // cache_way_select = tag_select;

        unique case (state)
            s_idle: begin   // do nothing until mem request
                if ((ufp_rmask | ufp_wmask) != 4'b0000) begin
                    cache_addr = ufp_addr[8:5];     // reg not updated yet
                    // req addr to be ready next cycle
                    csb[0] = 1'b0;
                    csb[1] = 1'b0;
                    csb[2] = 1'b0;
                    csb[3] = 1'b0;

                    // req lru data
                    lru_csb = 1'b0;

                    state_next = s_comp;
                end

                else begin
                    state_next = s_idle;
                end
            end
            s_comp: begin
                // if hit, state next idle
                // else if clean, next alloc
                // else dirty, next writeback
                if (tag_match & line_valid) begin
                    // hit: rdata ready/perform write, set resp high
                    compare_result = hit;

                    cache_way_select = tag_select;

                    // write to correct cacheline
                    if (ufp_wmask_reg != 4'b0000) begin
                        csb[tag_select] = 1'b0;
                        cache_data_web[tag_select] = 1'b0;
                        
                        cache_data_din[0] = ufp_wdata_out_0;
                        cache_data_din[1] = ufp_wdata_out_1;
                        cache_data_din[2] = ufp_wdata_out_2;
                        cache_data_din[3] = ufp_wdata_out_3;

                        cache_data_wmask[0] = ufp_wdata_wmask_0;
                        cache_data_wmask[1] = ufp_wdata_wmask_1;
                        cache_data_wmask[2] = ufp_wdata_wmask_2;
                        cache_data_wmask[3] = ufp_wdata_wmask_3;

                        //set dirty
                        cache_dirty_web[tag_select] = 1'b0;
                        cache_dirty_din[tag_select] = 1'b1;
                    end

                    // cache_data_din[0] = ufp_wdata_out_0;
                    // cache_data_din[1] = ufp_wdata_out_1;
                    // cache_data_din[2] = ufp_wdata_out_2;
                    // cache_data_din[3] = ufp_wdata_out_3;

                    // cache_data_wmask[0] = ufp_wdata_wmask_0;
                    // cache_data_wmask[1] = ufp_wdata_wmask_1;
                    // cache_data_wmask[2] = ufp_wdata_wmask_2;
                    // cache_data_wmask[3] = ufp_wdata_wmask_3;

                    // if read just send output to ufp, din data not used

                    ufp_resp = 1'b1;

                    // update lru
                    lru_csb = 1'b0;
                    lru_web = 1'b0;
                    lru_din = lru_next;

                    state_next = s_idle;
                end
                else if (~line_dirty) begin
                    // clean miss: read plru, req data, write to cachline
                    compare_result = clean_miss;

                    state_next = s_alloc;
                end
                else if (line_dirty) begin
                    compare_result = dirty_miss;

                    state_next = s_wb;
                end
                // else begin
                //     state_next = s_comp;
                // end
                // state_next = s_idle;
            end
            s_alloc: begin
                // req address from dfp, resp, alloc in cache, update lru
                dfp_addr = ufp_addr_reg & 32'hFFFFFFE0;
                dfp_read = 1'b1;

                if (dfp_resp) begin
                    // update cache line
                    csb[lru_select] = 1'b0;

                    cache_data_web[lru_select] = 1'b0;
                    cache_data_wmask[lru_select] = 32'hFFFFFFFF;
                    cache_data_din[lru_select] = dfp_rdata;

                    cache_valid_web[lru_select] = 1'b0;
                    cache_valid_din[lru_select] = 1'b1;

                    cache_dirty_web[lru_select] = 1'b0;
                    cache_dirty_din[lru_select] = 1'b0;

                    cache_tag_web[lru_select] = 1'b0;
                    cache_tag_din[lru_select] = ufp_addr_reg[31:9];

                    // // update lru
                    // lru_csb = 1'b0;
                    // lru_web = 1'b0;
                    // lru_din = lru_next;

                    // state_next = s_comp;
                    state_next = s_idle;
                end
                else begin
                    state_next = s_alloc;
                end
            end
            s_wb: begin
                // set addr and wdata, wait resp
                // dfp_addr = ufp_addr_reg & 32'hFFFFFFE0;
                dfp_addr = {{cache_tag_dout[lru_select]}, {ufp_addr_reg[8:5]}, {5'b00000}};
                dfp_write = 1'b1;
                dfp_wdata = cache_data_dout[lru_select];

                if (dfp_resp) begin
                    state_next = s_alloc;
                end
                else begin
                    state_next = s_wb;
                end
            end
            default:begin
                state_next = s_idle;
            end
        endcase
    end

endmodule
