/**
 * Class of transaction
 *  - Generate the test sequences
 */

`ifndef CLASS_TRANSACTION_SV
`define CLASS_TRANSACTION_SV

`include "test/ins_definition.sv"

typedef struct {
   opfmt_t fmt;
   bit [6:0] bit_op;
   bit [2:0] bit_f3;
   bit [6:0] bit_f7;
} funcmeta_t;

class transaction;
   // Members of class
   rand bit rst;
   rand instruction_t i1;
   bit [31:0] PC;

   //for data/memory dependency
   bit [4:0] rec_rd;
   bit [4:0] rec_rs1;
   bit [11:0] rec_imm_12;
   bit [4:0] rd_unused[bit [4:0]];
   bit [4:0] rd_used[bit [4:0]];

   bit force_rd;
   bit [4:0] forced_rd;
   bit force_invalid;
   bit force_rst;
   bit forced_rst;

   //op-code & function table
   funcmeta_t funcdic[] = '{
      '{FMT_R, 7'b0110011, 3'b000, 7'b0000000 },  // ADD
      '{FMT_I, 7'b0010011, 3'b000, 7'b0000000 },  // ADDI
      '{FMT_R, 7'b0110011, 3'b000, 7'b0100000 },  // SUB
      //'{FMT_U, 7'b0110111, 3'b000, 7'b0000000 },  // LUI
      '{FMT_R, 7'b0110011, 3'b100, 7'b0000000 },  // XOR   5
      '{FMT_I, 7'b0010011, 3'b100, 7'b0000000 },  // XORI
      '{FMT_R, 7'b0110011, 3'b110, 7'b0000000 },  // OR
      '{FMT_I, 7'b0010011, 3'b110, 7'b0000000 },  // ORI
      '{FMT_R, 7'b0110011, 3'b111, 7'b0000000 },  // AND
      '{FMT_I, 7'b0010011, 3'b111, 7'b0000000 },  // ANDI  10
      '{FMT_R, 7'b0110011, 3'b001, 7'b0000000 },  // SLL
      '{FMT_I, 7'b0010011, 3'b001, 7'b0000000 },  // SLLI
      '{FMT_R, 7'b0110011, 3'b101, 7'b0000000 },  // SRL
      '{FMT_I, 7'b0010011, 3'b101, 7'b0000000 },  // SRLI
      '{FMT_R, 7'b0110011, 3'b101, 7'b0100000 },  // SRA   15
      '{FMT_I, 7'b0010011, 3'b101, 7'b0100000 },  // SRAI
      '{FMT_R, 7'b0110011, 3'b010, 7'b0000000 },  // SLT
      '{FMT_I, 7'b0010011, 3'b010, 7'b0000000 },  // SLTI
      //'{FMT_R, 7'b0110011, 3'b011, 7'b0000000 },  // SLTU
      //'{FMT_I, 7'b0010011, 3'b011, 7'b0000000 },  // SLTIU 20
      '{FMT_I, 7'b0000011, 3'b000, 7'b0000000 },  // LB
      '{FMT_I, 7'b0000011, 3'b001, 7'b0000000 },  // LH
      '{FMT_I, 7'b0000011, 3'b010, 7'b0000000 },  // LW
      '{FMT_I, 7'b0000011, 3'b100, 7'b0000000 },  // LBU
      '{FMT_I, 7'b0000011, 3'b101, 7'b0000000 },  // LHU   25
      '{FMT_S, 7'b0100011, 3'b000, 7'b0000000 },  // SB
      '{FMT_S, 7'b0100011, 3'b001, 7'b0000000 },  // SH
      '{FMT_S, 7'b0100011, 3'b010, 7'b0000000 },  // SW
      '{FMT_S, 7'b1100011, 3'b000, 7'b0000000 },  // BEQ
      '{FMT_S, 7'b1100011, 3'b001, 7'b0000000 },  // BNE   30
      '{FMT_S, 7'b1100011, 3'b100, 7'b0000000 },  // BLT
      '{FMT_S, 7'b1100011, 3'b101, 7'b0000000 },  // BGE
      //'{FMT_S, 7'b1100011, 3'b110, 7'b0000000 },  // BLTU
      //'{FMT_S, 7'b1100011, 3'b111, 7'b0000000 },  // BGEU
      '{FMT_U, 7'b1101111, 3'b000, 7'b0000000 },  // JAL   35
      '{FMT_U, 7'b1100111, 3'b000, 7'b0000000 }   // JR
   };

   environment env;

   // Constraints
   
   constraint c_order {
      solve i1.optype before i1.category;
      solve i1.category before i1.func;
      solve i1.func before i1.rs1;
      solve i1.func before i1.rs2;	
      solve i1.func before i1.rd;	  
   }

   constraint dist_rst {
      if (env.preload_mem)
         rst == 0;
      else if (env.d_rst_cycle == 0)
         rst == 0;
      else if (env.d_rst_cycle == env.cycles)
         rst == 1;
      else
         rst dist { 1 := env.d_rst_cycle, 0 := env.cycles-env.d_rst_cycle };
   }

   constraint dist_noop {
      if (env.d_noop_cycle == 0)
         i1.valid == 1;
      else if (env.d_op_cycle == 0)
         i1.valid == 0;
      else
         i1.valid dist { 0 := env.d_noop_cycle, 1 := env.d_op_cycle};
   }

   constraint dist_optype {
      if (env.d_alu_cycle == env.cycles)
         i1.optype == OP_AL;
      else if (env.d_ls_cycle == env.cycles)
         i1.optype == OP_SL;
      else if (env.d_bj_cycle == env.cycles)
         i1.optype == OP_JB;
      else
         i1.optype dist {OP_AL := env.d_alu_cycle, OP_SL := env.d_ls_cycle, OP_JB := env.d_bj_cycle};
   }

   constraint c_category {
	  if (i1.optype == OP_AL)      i1.category inside {ARI, LGC, SFT, CMP};
	  else if (i1.optype == OP_SL) i1.category inside {LD, ST};
	  else                         i1.category inside {BR, JP};
   }

   constraint c_func {
      if (i1.category == ARI)      i1.func inside {ADD, ADDI, SUB};//, LUI};
	  else if (i1.category == LGC) i1.func inside {XOR, XORI, OR, ORI, AND, ANDI};
	  else if (i1.category == SFT) i1.func inside {SLL, SLLI, SRL, SRLI, SRA, SRAI};
     else if (i1.category == CMP) i1.func inside {SLT, SLTI};//, SLTU, SLTIU};
	  else if (i1.category == LD)  i1.func inside {LB, LH, LW, LBU, LHU};
	  else if (i1.category == ST)  i1.func inside {SB, SH, SW};
     else if (i1.category == BR)  i1.func inside {BEQ, BNE, BLT, BGE};//, BLTU, BGEU};
	  else                         i1.func inside {JAL, JR};
   }

   constraint c_force_lw {
      i1.optype == OP_SL;
      i1.category == LD;
      i1.func == LW;
      i1.valid == 1;
   }

   constraint c_rd {
	  if(i1.category == JP) i1.rd == 5'd0;  //jump
      else if(i1.optype == OP_AL || i1.category == LD) { 
         if (rd_unused.size() == 0) {
            i1.rd == 5'd0;
         } else {
            i1.rd inside rd_unused;  //R&I type
            i1.rd > 5'd0;
         }
	  }
   }   

   constraint c_rs1 {
	  i1.rs1 > 5'd0;
   }     
   
   constraint c_rs2 {
	  i1.rs2 > 5'd0;
   }   
   
   constraint c_data_dep {
      if (env.preload_mem) {
         !(i1.rs1 inside rd_used);
         !(i1.rs2 inside rd_used);
      } else if(env.data_ctrl) {
         if(env.data_depend && rec_rd != 0) {
			if(i1.category == ST) i1.rs2 == rec_rd;
			else i1.rs1 == rec_rd;
		} else { // Independent
         !(i1.rs2 inside rd_used);
         !(i1.rs1 inside rd_used);
		}
	  }
   }
   
   constraint c_mem_dep {   
 		if(env.mem_ctrl) {
			if(env.mem_depend) {
				if(i1.category == LD || i1.category == ST) {
					i1.rs1 == rec_rs1;
					i1.imm_12 == rec_imm_12;
				}
			} else {
				i1.imm_12 != rec_imm_12;
		    }
	    } 	
	}

   // Constructor & pre/post_randomize
   function new(ref environment e);
      env = e;
      srandom(env.random_seed);

      PC = 0;

      rec_rd = 0;
      rec_rs1 = 0;
      rec_imm_12 = 0;
      for (int i = 1; i < 32; i++)
         rd_unused[i] = i;

      force_rd = 0;
      forced_rd = 0;
      force_invalid = 0;
      force_rst = 0;
      forced_rst = 0;
   endfunction

   function void post_randomize;
      // Apply masks
      i1.rd &= env.m_reg_rd;
      i1.rs1 &= env.m_reg_r1;
      i1.rs2 &= env.m_reg_r2;
      i1.imm_12 &= env.m_imm_12;
      i1.imm_20 &= env.m_imm_20;

      if (force_rst)
         rst = forced_rst;

      if (force_invalid || rst)
         i1.valid = 0;
      if ((i1.optype == OP_AL || i1.category == LD) && i1.rd == 0)
         i1.valid = 0;

      // For rd
      if (force_rd)
         i1.rd = forced_rd;

      if (rst) begin
         rec_rd = 0;
         rec_rs1 = 0;
         rec_imm_12 = 0;
         for (int i = 1; i < 32; i++) begin
            rd_unused[i] = i;
            rd_used.delete(i);
         end

         force_rd = 0;
         forced_rd = 0;
         force_invalid = 0;
      end

      // Record for dependency
      if (i1.valid) begin
         i1.PC = PC++;
         rec_rd = i1.rd;
         rec_rs1 = i1.rs1;
         rec_imm_12 = i1.imm_12;
         if (i1.optype == OP_AL || i1.category == LD) begin
            rd_unused.delete(rec_rd);
            rd_used[rec_rd] = rec_rd;
         end
      end

      build_instruction(i1);

      if (env.dbg_msg) begin
         if (i1.valid) begin
            $display("%s/%s/%s (f7 %b f3 %b op %b)", i1.optype, i1.category, i1.func, funcdic[i1.func].bit_f7, funcdic[i1.func].bit_f3, funcdic[i1.func].bit_op);
            $display("%b(%d)/%b(%d)/%b(%d)/%b/%b", i1.rd, i1.rd, i1.rs1, i1.rs1, i1.rs2, i1.rs2, i1.imm_12, i1.imm_20);
            $display("               |  7  || 5 || 5 ||3|| 5 ||  7  |");
            $display("PC %d: %b (0x%h)\n", i1.PC, i1.instr, i1.instr);
         end else begin
            $display("Invalid instruction generated\n");
         end
      end
   endfunction

   // Tasks of class

   // Functions of class
   function void build_instruction(ref instruction_t i);
      funcmeta_t tmp = funcdic[i.func];
	  
      if (tmp.fmt == FMT_R) begin
         i.instr = {tmp.bit_f7, i.rs2, i.rs1, tmp.bit_f3, i.rd, tmp.bit_op};
      end else if (tmp.fmt == FMT_S) begin
         i.instr = {i.imm_12[11:5], i.rs2, i.rs1, tmp.bit_f3, i.imm_12[4:0], tmp.bit_op};
      end else if (tmp.fmt == FMT_I) begin
         if (i.func == SLLI || i.func == SRLI || i.func == SRAI)
            i.imm_12 = {tmp.bit_f7, i.imm_12[4:0]};
         i.instr = {i.imm_12, i.rs1, tmp.bit_f3, i.rd, tmp.bit_op};
      end else if (tmp.fmt == FMT_U) begin
         i.instr = {i.imm_20, i.rd, tmp.bit_op};
      end else begin
         i.instr = '0;
      end
   endfunction

   function void do_force_rd(bit en, bit [4:0] idx);
      force_rd = en;
      forced_rd = idx;
   endfunction

   function void do_force_reset(bit en, bit rst);
      force_rst = en;
      forced_rst = rst;
   endfunction

   function void do_force_invalid(bit en);
      force_invalid = en;
   endfunction

   function int release_rd(bit [4:0] idx);
      rd_used.delete(idx);
      rd_unused[idx] = idx;
   endfunction

endclass

`endif
