/****
 * The interface for test
 *  - The interface to connect between top DUT and the testbench
 */

interface ifc_test #(parameter INSTR_WIDTH = 32,
                     parameter PC_WIDTH = 32,
                     parameter ADDR_WIDTH = 5,
                     parameter MEM_WIDTH = 32,
                     parameter DATA_WIDTH = 32)
(input bit clk);

   logic rst;

   // To intruction decoder
   logic [PC_WIDTH - 1:0]    PC_in1;
   logic [INSTR_WIDTH - 1:0] instruction1;
   logic                     ins1_valid;
   logic [PC_WIDTH - 1:0]    PC_in2;
   logic [INSTR_WIDTH - 1:0] instruction2;
   logic                     ins2_valid;

   // Memory access
   logic                    mem_store_en;
   logic [1:0]              mem_store_type;
   logic [MEM_WIDTH - 1:0]  mem_store_addr;
   logic [DATA_WIDTH - 1:0] mem_store_value;
   logic                    mem_load_en;
   logic [1:0]              mem_load_type;
   logic [MEM_WIDTH - 1:0]  mem_load_addr;
   logic [DATA_WIDTH - 1:0] mem_load_value;
   logic                    mem_load_valid;

   // Feedback to testbench
   logic                  ROB_full;
   logic [PC_WIDTH - 1:0] jump_PC;
   logic                  jump_en;
   logic [PC_WIDTH - 1:0] branch_PC;
   logic                  branch_en;
   logic [PC_WIDTH - 1:0] flush_PC;
   logic                  flush_en;

   // Commitment outputs
   logic [ADDR_WIDTH - 1:0] WB_target1;
   logic [DATA_WIDTH - 1:0] WB_data1;
   logic                    WB_en1;
   logic [ADDR_WIDTH - 1:0] WB_target2;
   logic [DATA_WIDTH - 1:0] WB_data2;
   logic                    WB_en2;

   clocking cb @(posedge clk);
      output rst, PC_in1, instruction1, ins1_valid,
                  PC_in2, instruction2, ins2_valid,
                  mem_load_value, mem_load_valid;
      input  ROB_full, jump_PC, jump_en, branch_PC, branch_en, flush_PC,
             flush_en,
             WB_target1, WB_data1, WB_en1, WB_target2, WB_data2, WB_en2,
             mem_store_en, mem_store_type, mem_store_addr, mem_store_value,
             mem_load_en, mem_load_type, mem_load_addr;
   endclocking

   modport dut (
      input  clk, rst, PC_in1, instruction1, ins1_valid,
                       PC_in2, instruction2, ins2_valid,
                       mem_load_value, mem_load_valid,
      output ROB_full, jump_PC, jump_en, branch_PC, branch_en, flush_PC,
             flush_en,
             WB_target1, WB_data1, WB_en1, WB_target2, WB_data2, WB_en2,
             mem_store_en, mem_store_type, mem_store_addr, mem_store_value,
             mem_load_en, mem_load_type, mem_load_addr
   );

   modport bench (clocking cb);

endinterface
