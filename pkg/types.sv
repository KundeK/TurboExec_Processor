package rv32i_types;
    localparam integer     PHYS_REG_BITS = 6;
    localparam integer     ROB_NUM_BITS = 4;

    typedef enum logic [2:0] {
        invalid = 3'b000,
        alu = 3'b001,
        mult = 3'b010,
        div = 3'b011,
        mem = 3'b100,
        br = 3'b101
    } instr_type_t;

    typedef enum logic {
        rs1_out = 1'b0,
        pc_out  = 1'b1
    } alu_m1_sel_t;

    // more mux def here
    typedef enum logic {
        rs2_out = 1'b0,
        imm_out = 1'b1
    } alu_m2_sel_t;

    typedef enum logic {
        alu_out = 1'b0,
        cmp_out = 1'b1
    } alu_cmp_sel_t;

    typedef enum logic [1:0]{
        no_wb = 2'b00,
        ex_out = 2'b01,
        mm_out = 2'b10,
        pcn_out = 2'b11
    } rd_wb_sel_t;

    typedef enum logic [1:0]{
        no = 2'b00,
        ld = 2'b01,
        st = 2'b11
    } mm_op_sel_t;

    // mp_verif/pkg/types
    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [2:0] {
        mul_f3_mul      = 3'b000,
        mul_f3_mulh     = 3'b001,
        mul_f3_mulsu    = 3'b010,
        mul_f3_mulu     = 3'b011,
        mul_f3_div      = 3'b100,
        mul_f3_divu     = 3'b101,
        mul_f3_rem      = 3'b110,
        mul_f3_remu     = 3'b111
    } mul_f3_t;

    typedef enum logic [2:0] {
        alu_op_add     = 3'b000,
        alu_op_sll     = 3'b001,
        alu_op_sra     = 3'b010,
        alu_op_sub     = 3'b011,
        alu_op_xor     = 3'b100,
        alu_op_srl     = 3'b101,
        alu_op_or      = 3'b110,
        alu_op_and     = 3'b111
    } alu_ops;

    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        struct packed {
            logic [11:5] imm_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_bot;
            rv32i_opcode opcode;
        } b_type;

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t;

    typedef union packed {
        logic [2:0] word;
        arith_f3_t  arith_f3;
        load_f3_t   load_f3;
        store_f3_t  store_f3;
        branch_f3_t branch_f3;
    } funct3_t;

    typedef enum logic [6:0] {
        base           = 7'b0000000,
        variant        = 7'b0100000,
        floating       = 7'b0000001
    } funct7_t;

    typedef logic [4:0] reg_t;

    // typedef struct packed {
    //     alu_m1_sel_t        alu_m1_sel;
    //     alu_m2_sel_t        alu_m2_sel;
    //     alu_cmp_sel_t       alu_cmp_sel;

    //     // logic               rd_v_sel;
    //     rd_wb_sel_t         rd_wb_sel;

    //     mm_op_sel_t         mm_op_sel;

    //     logic       [2:0]   funct3;

    //     logic               regf_we;
    //     logic       [4:0]   rs1_s;
    //     logic       [4:0]   rs2_s;
    //     logic       [4:0]   rd_s;
    //     logic       [31:0]  rs1_v;
    //     logic       [31:0]  rs2_v;
    //     logic       [31:0]  rd_v;

    //     alu_ops             alu_op;
    //     branch_f3_t         cmp_op;

    //     logic               br_en;
    //     logic               branch_inst;

    //     logic               mm_bub;

    //     logic               invalid;

    //     logic               jalr;

    //     logic       [31:0]  ex_out;
    //     logic       [31:0]  mm_out;

    //     logic       [31:0]  imm;
    // } ctrl_word_t;

    typedef struct packed {
        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;
        alu_cmp_sel_t       alu_cmp_sel;

        alu_ops             alu_op;
        branch_f3_t         cmp_op;

        mm_op_sel_t         mm_op_sel;
    } ctrl_word_t;

    typedef struct packed {
        logic           valid;      // id
        logic   [63:0]  order;      // if
        logic   [31:0]  inst;       // if
        logic   [4:0]   rs1_addr;   // id
        logic   [4:0]   rs2_addr;   // id
        logic   [31:0]  rs1_rdata;  // ex
        logic   [31:0]  rs2_rdata;  // ex
        logic           regf_we;    // id
        logic   [4:0]   rd_addr;    // id
        logic   [31:0]  rd_wdata;   // wb
        logic   [31:0]  pc_rdata;   // if
        logic   [31:0]  pc_wdata;   // if
        logic   [31:0]  mem_addr;   // if/mm
        logic   [3:0]   mem_rmask;  // if/mm
        logic   [3:0]   mem_wmask;  // if/mm
        logic   [31:0]  mem_rdata;  // if/mm
        logic   [31:0]  mem_wdata;  // if/mm
    } monitor_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;

        logic               load_ir;
        // logic               valid;

        // alu_m1_sel_t        alu_m1_sel;
        ctrl_word_t         ctrl_word;
        monitor_t           monitor;
    } if_id_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic               valid;

        // alu_m1_sel_t        alu_m1_sel;
        ctrl_word_t         ctrl_word;

        monitor_t           monitor;
    } id_ex_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic               valid;

        // alu_m1_sel_t        alu_m1_sel;
        ctrl_word_t         ctrl_word;

        monitor_t           monitor;
    } ex_mm_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic               valid;

        // alu_m1_sel_t        alu_m1_sel;
        ctrl_word_t         ctrl_word;

        monitor_t           monitor;
    } mm_wb_t;

    typedef struct packed {
        logic               valid;
        logic   [31:0]      pc;
        logic   [63:0]      order;

        instr_t             data;
        instr_type_t        instr_type;

        logic   [31:0]      imm;

        logic   [4:0]       rs1_addr;
        logic   [PHYS_REG_BITS-1:0]       rs1_paddr;
        logic   [31:0]      rs1_data;
        logic               rs1_rdy;
        logic               rs1_used;
        
        logic   [4:0]       rs2_addr;
        logic   [PHYS_REG_BITS-1:0]       rs2_paddr;
        logic               rs2_rdy;
        logic   [31:0]      rs2_data;
        logic               rs2_used;

        logic   [4:0]       rd_addr;
        logic   [PHYS_REG_BITS-1:0]     rd_paddr;
        logic   [31:0]      rd_data;

        logic   [31:0]      br_addr;
        logic               br_en;
        logic               br_predict;     // 0 - not taken, 1 - taken

        logic   [ROB_NUM_BITS-1:0]      rob_addr;

        logic   [31:0]      mem_addr;
        logic   [3:0]       mem_wmask;
        logic   [3:0]       mem_rmask;
        logic   [31:0]      mem_rdata;
        logic   [31:0]      mem_wdata;
    } ooo_instr_t;

    typedef struct packed {
        // logic           valid;
        logic           status;
        ooo_instr_t     data;
        // monitor_t       monitor;

        logic   [4:0]   rd_addr;
        logic   [PHYS_REG_BITS-1:0]     rd_paddr;
    } rob_entry_t;

    typedef struct packed {
        logic           valid;
        logic   [4:0]   rd_addr;
        logic   [PHYS_REG_BITS-1:0]     rd_paddr;     
        logic   [31:0]  rd_data;     
    } wb_bus_t;

endpackage
