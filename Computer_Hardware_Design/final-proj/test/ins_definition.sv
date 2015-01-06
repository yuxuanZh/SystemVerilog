/**
 * Definition of the Instruction Set
 */

`ifndef INS_DEFINITION_SV
`define INS_DEFINITION_SV

typedef bit [31:0] b32_t;
typedef bit [19:0] b20_t;
typedef bit [11:0] b12_t;
typedef bit [9:0]  b10_t;
typedef bit [7:0]  b8_t;
typedef bit [6:0]  b7_t;
typedef bit [4:0]  b5_t;
typedef bit [2:0]  b3_t;
typedef bit [1:0]  b2_t;

typedef enum {FAIL, PASS} chkres_t;
typedef enum {FAILURE, SUCCESS} res_t;
typedef enum {FALSE, TRUE} bool_t;

typedef enum {OP_AL, OP_SL, OP_JB} optype_t;
typedef enum {ARI, LGC, SFT, CMP, LD, ST, BR, JP} category_t;
typedef enum {FMT_R, FMT_I, FMT_S, FMT_U} opfmt_t;
typedef enum {ADD, ADDI, SUB,// LUI,
              XOR, XORI, OR, ORI, AND, ANDI,
              SLL, SLLI, SRL, SRLI, SRA, SRAI,
              SLT, SLTI,// SLTU, SLTIU,
              LB, LH, LW, LBU, LHU,
              SB, SH, SW,
              BEQ, BNE, BLT, BGE,// BLTU, BGEU,
              JAL, JR} function_t;

typedef struct {
   rand optype_t     optype;
   rand category_t   category;
   rand function_t   func;

   rand bit [4:0] rd;   // R/I/U-type
   rand bit [4:0] rs1;  // R/I/S-type
   rand bit [4:0] rs2;  // R/S-type
   rand bit [11:0] imm_12; // S/I-type
   rand bit [19:0] imm_20; // U-type
   bit [31:0] instr;
   rand bit valid;
   bit [31:0] PC;

} instruction_t;

function automatic void chk_assert(chkres_t chk, string str);
   assert(chk) else $fatal("Check assertion failed: %s", str);
endfunction

`endif
