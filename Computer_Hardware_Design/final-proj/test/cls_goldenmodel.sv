/**
 * Class of the design (the golden model)
 *  - The golden model of the design
 */

`ifndef CLASS_GOLDENMODEL_SV
`define CLASS_GOLDENMODEL_SV

`include "test/cls_regfile.sv"
`include "test/ins_definition.sv"

typedef struct {

   bit [31:0] PC;
   bit [4:0]  rd;  
   bit [31:0] value;
   bit [31:0] addr;
   bit [1:0] JB; // 1x: JB type,  x1: branch taken,   x0: not taken
   bit [1:0] LS; // 10: load, 01: store
} commit_t;

class goldenmodel;
   // Members of class

   environment env;
   regfile rf;

   commit_t commit[$];
   int commit_num;
   int last_cmt_size;
   
   // Constructor
   function new(ref environment e, ref regfile r);
      env = e;
      rf = r;
      commit_num = 0;
      last_cmt_size = 0;
   endfunction

   // Tasks of class
   task load_ins(instruction_t i, output bit load_en, bit [1:0] load_type, bit [31:0] load_addr); 
      int rs1_value;
	  bit rs1_valid;
      int imm_ext_32 = {{20{i.imm_12[11]}}, i.imm_12};
	  
	  rf.read(i.rs1, rs1_value, rs1_valid);
	  
      if(i.valid && i.category == LD) begin
	     load_en = 1;
	     load_addr = rs1_value + imm_ext_32;
		 
	     if(i.func == LW)       			     load_type = 2'b10;
		 else if(i.func == LH || i.func == LHU)  load_type = 2'b01;
		 else                                    load_type = 2'b00;
      end else begin
	     load_en = 0;
      end
	endtask
	  
   task print_queue;
      $display("commit queue contains ");
      for (int i = 0; i < commit.size(); i++) begin
         $display ("PC: %-5d, rd: %-2d, data: 0x%-8h, addr: 0x%-8h, JB: %-2b, LS: %-2b", 
		           commit[i].PC, commit[i].rd, commit[i].value, commit[i].addr, commit[i].JB, commit[i].LS);
      end
         $display("\n");
   endtask
	  
	  
   // Functions of class
   function void on_reset(bit rst);
      if (rst)
         commit = {};
   endfunction

   function res_t flush_from_pc(b32_t pc);
      int pc_found = -1;
      for (int i = 0; i < commit.size(); i++) begin
         if (commit[i].PC == pc) begin
            pc_found = i;
            break;
         end
      end
      if (pc_found < 0) begin
         return FAILURE;
      end else begin
         for (int i = pc_found; i < commit.size(); i++) begin
            commit.delete(pc_found);
         end
         return SUCCESS;
      end
   endfunction
 
   function void update(instruction_t i);
      int rs1_value;
      bit [31:0] rs1_value_uns = rs1_value;
	  int rs2_value;
	  bit [31:0] rs2_value_uns = rs2_value;
	  int rd_value;
	  bit [31:0] store_addr;
	  int imm_ext_32 = {{20{i.imm_12[11]}}, i.imm_12};
	  bit [31:0] imm_32 = {{20{i.imm_12[11]}}, i.imm_12};
	  int jump_imm_32 = {{12{i.imm_20[19]}}, i.imm_20};
	  bit rs1_valid, rs2_valid, pc_valid;
	  bit [31:0] pc_value;
	  
      rf.read(i.rs1, rs1_value, rs1_valid);
	  rf.read(i.rs2, rs2_value, rs2_valid);
	  rf.read(i.rd, pc_value, pc_valid); //JR
	  
      if(i.valid) begin
		 case(i.func) 
			ADD: begin 
			   rd_value = rs1_value + rs2_value;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			ADDI: begin 
			   rd_value = rs1_value + imm_ext_32;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			SUB: begin 
			   rd_value = rs1_value - rs2_value;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end/*
		   LUI: begin
			   rd_value = {i.imm_20, 12'b0};
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end*/
			XOR: begin 
			   rd_value = rs1_value ^ rs2_value;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			XORI: begin 
			   rd_value = rs1_value ^  imm_ext_32;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			OR: begin 
			   rd_value = rs1_value | rs2_value;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			ORI: begin 
			   rd_value = rs1_value |  imm_ext_32;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			AND: begin 
			   rd_value = rs1_value & rs2_value;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			ANDI: begin 
			   rd_value = rs1_value & imm_ext_32;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			SLL: begin
			   rd_value = rs1_value << rs2_value[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});	
			end   
			SLLI: begin
			   rd_value = rs1_value << imm_32[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end   
			SRL: begin
			   rd_value = rs1_value >> rs2_value[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end   
			SRLI: begin
			   rd_value = rs1_value >> imm_32[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end   
			SRA: begin
			   rd_value = rs1_value >>> rs2_value[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end  
			SRAI: begin
			   rd_value = rs1_value >>> imm_32[4:0];
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});	
			end   
			SLT: begin
			   rd_value = (rs1_value < rs2_value) ? 32'd1 : 32'd0;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end   
			SLTI: begin
			   rd_value = (rs1_value < imm_ext_32) ? 32'd1 : 32'd0;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});	
			end/*
			SLTU: begin
			   rd_value = (rs1_value_uns < rs2_value_uns) ? 32'd1 : 32'd0;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end
			SLTIU: begin
			   rd_value = (rs1_value_uns < imm_32) ? 32'd1 : 32'd0;
			   rf.write(i.rd, rd_value);
			   commit.push_back('{i.PC, i.rd, rd_value, 32'd0, 2'b00, 2'b00});
			end*/
			SB: begin
			   store_addr = rs1_value + imm_ext_32;
			   commit.push_back('{i.PC, 5'd0, rs2_value, store_addr, 2'b00, 2'b01}); //rs2_value = store_value
			end
			SH: begin
			   store_addr = rs1_value + imm_ext_32;
			   commit.push_back('{i.PC, 5'd0, rs2_value, store_addr, 2'b00, 2'b01});
			end 
			SW: begin
			   store_addr = rs1_value + imm_ext_32;
			   commit.push_back('{i.PC, 5'd0, rs2_value, store_addr, 2'b00, 2'b01});
			end 
			BEQ: begin
			   if(rs1_value == rs2_value) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end	
			BNE: begin
			   if(rs1_value != rs2_value) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end	
			BLT: begin
			   if(rs1_value < rs2_value) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end	
			BGE: begin
			   if(rs1_value >= rs2_value) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end/*
			BLTU: begin
			   if(rs1_value_uns < rs2_value_uns) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end	
			BLTU: begin
			   if(rs1_value_uns >= rs2_value_uns) begin
			      rd_value = i.PC + imm_ext_32; //rd_value = branch_PC
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b11, 2'b00}); 
			   end else begin	
     			  rd_value = i.PC + 32'd1;
				  commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			   end  
			end*/
			JAL: begin
			   rd_value = i.PC + jump_imm_32; //rd_value = jump_PC
			   commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			end	
			JR: begin
			   rd_value = pc_value; //jump back pc
			   commit.push_back('{i.PC, 5'd0, rd_value, 32'd0, 2'b10, 2'b00}); 
			end				
		 endcase
		 
		 
	   end
	   
	endfunction
      
    function void update_load(instruction_t i, bit [31:0] load_addr, bit [31:0] load_value);
	
	   bit	[31:0] wb_value;
	   
	   case (i.func)
	      LB: wb_value = {{24{load_value[7]}}, load_value[7:0]};
		  LH: wb_value = {{16{load_value[15]}}, load_value[15:0]};
		  LW: wb_value = load_value;
		  LBU: wb_value = {24'd0, load_value[7:0]};
		  LHU: wb_value = {16'd0, load_value[15:0]};
	      default: wb_value = load_value;
	   endcase
		
		rf.write(i.rd, wb_value);
	    commit.push_back('{i.PC, i.rd, wb_value, load_addr, 2'b00, 2'b10});
    endfunction

   function chkres_t per_check(bit rst);
      chkres_t rval = PASS;
      if (env.per_check && !rst) begin
         if (commit.size() > 12) begin
            $display("[Performance][error] No commits???");
            rval = FAIL;
         end
      end
      return rval;
   endfunction

   function chkres_t unknown_check(logic bit1);
      chkres_t rval = PASS;
      if (bit1 === 1'bx || bit1 === 1'bz) begin
         $display("Should not be x or z");
         rval = FAIL;
      end
      return rval;
   endfunction
	
	//check functions
   function chkres_t reset_check(bit rst, logic branch_en, logic jump_en, logic flush_en,
                           logic WB_en1, logic WB_en2, logic store_en, logic load_en);
      chkres_t rval = PASS;

      chk_assert(unknown_check(branch_en), "Unknown branch_en in reset_check");
      chk_assert(unknown_check(jump_en), "Unknown jump_en in reset_check");
      chk_assert(unknown_check(flush_en), "Unknown flush_en in reset_check");
      chk_assert(unknown_check(WB_en1), "Unknown WB_en1 in reset_check");
      chk_assert(unknown_check(WB_en2), "Unknown WB_en2 in reset_check");
      chk_assert(unknown_check(store_en), "Unknown store_en in reset_check");
      chk_assert(unknown_check(load_en), "Unknown, load_en in reset_check");

      if (rst) begin
         if (branch_en || jump_en || flush_en || WB_en1 || WB_en2 || store_en || load_en) begin
            $display("[issue][error] Should be nothing for reset");
            rval = FAIL;
         end
      end

      return rval;
   endfunction

	function chkres_t branch_check(bit rst, logic branch_en, logic [31:0] target_pc, logic [31:0] ins_pc);
      chkres_t rval = PASS;

      chk_assert(unknown_check(branch_en), "Unknown branch_en in branch_check");

      if (rst) begin
         if (branch_en) begin
            $display("[issue][error] Should be nothing for reset");
            rval = FAIL;
         end
      end else if(branch_en) begin
         for (int i = 0; i < 32; i++) begin
            chk_assert(unknown_check(target_pc[i]), "Unknown target_pc bit in branch_check");
            chk_assert(unknown_check(ins_pc[i]), "Unknown ins_pc bit in branch_check");
         end
	      for (int i = 0; i < commit.size(); i++) begin
		     if(commit[i].PC == ins_pc && commit[i].JB == 2'b11) begin
              if(commit[i].value != target_pc) begin
				   $display("[Issue][error] Branch Target PC mismatch");
               rval = FAIL;
            end
			 end
		  end
	   end

      return rval;
	endfunction
	  
	function chkres_t jump_check(bit rst, logic jump_en, logic [31:0] target_pc, logic [31:0] ins_pc);
      chkres_t rval = PASS;

      chk_assert(unknown_check(jump_en), "Unknown jump_en in jump_check");

      if (rst) begin
         if (jump_en) begin
            $display("[issue][error] Should be nothing for reset");
            rval = FAIL;
         end
      end else if(jump_en) begin
         for (int i = 0; i < 32; i++) begin
            chk_assert(unknown_check(target_pc[i]), "Unknown target_pc bit in jump_check");
            chk_assert(unknown_check(ins_pc[i]), "Unknown ins_pc bit in jump_check");
         end
	      for (int i = 0; i < commit.size(); i++) begin
		     if(commit[i].PC == ins_pc && commit[i].JB == 2'b11) begin
              if(commit[i].value != target_pc) begin
				   $display("[Issue][error] Jump Target PC mismatch");
               rval = FAIL;
            end
			 end
		  end
	   end

      return rval;
	endfunction

	
	function chkres_t wb_check(bit rst, logic WB_en1, logic [4:0] WB_target1, logic [31:0] WB_data1, 
	                       logic WB_en2, logic [4:0] WB_target2, logic [31:0] WB_data2);
      chkres_t rval = PASS;
      int cmt1 = 0, cmt2 = 0;
      int num = 0;
	   commit_num = 0;

      chk_assert(unknown_check(WB_en1), "Unknown WB_en1 in wb_check");
      chk_assert(unknown_check(WB_en2), "Unknown WB_en2 in wb_check");

      if (rst) begin
         if (WB_en1 || WB_en2) begin
            $display("[Commit][error] Should be nothing for reset");
            rval = FAIL;
            return rval;
         end
      end

      if (env.per_check && !env.preload_mem) begin
         if (WB_en1 ^ WB_en2) begin
            $display("[Commit][error] There should not be only one commit under performance test");
            rval = FAIL;
         end
      end

	   if(WB_en1) begin
         for (int i = 0; i < 5; i++) begin
            chk_assert(unknown_check(WB_target1[i]), "Unknown WB_target1 bit in wb_check");
         end
         for (int i = 0; i < 32; i++) begin
            chk_assert(unknown_check(WB_data1[i]), "Unknown WB_data1 bit in wb_check");
         end
         if(commit[0].rd != WB_target1) begin
	         $display("[Commit][error] First Write-back Index error");
            rval = FAIL;
         end else if(commit[0].value != WB_data1) begin
		     $display("[Commit][error] First Write-back Data error");
           rval = FAIL;
		  end
        num++;
        cmt1 = 1;
	   end else begin
         if(commit.size() > 0 && commit[0].JB[1] == 1) begin //branch/jump
            num++;
            cmt1 = 1;
         end
	   end
			 
	   
	   if(WB_en2) begin
         for (int i = 0; i < 5; i++) begin
            chk_assert(unknown_check(WB_target2[i]), "Unknown WB_target2 bit in wb_check");
         end
         for (int i = 0; i < 32; i++) begin
            chk_assert(unknown_check(WB_data2[i]), "Unknown WB_data2 bit in wb_check");
         end
         if(commit[1].rd != WB_target2) begin
	         $display("[Commit][error] Second Write-back Index mismatch");
            rval = FAIL;
         end else if(commit[1].value != WB_data2) begin
		     $display("[Commit][error] Second Write-back Data mismatch");
           rval = FAIL;
		   end
         num++;
         cmt2 = 1;
	   end else begin
         if(commit.size() > 1 && commit[1].JB[1] == 1) begin
            num++;
            cmt2 = 1;
         end
	   end

      if (cmt2)
         commit.delete(1);
      if (cmt1)
         commit.delete(0);

	   commit_num += num;

      return rval;
	endfunction

	


	function chkres_t store_check(bit rst, logic store_en, logic [1:0] store_type, logic [31:0] store_addr, logic [31:0] store_value);
      chkres_t rval = PASS;
	   int num = 0;

      chk_assert(unknown_check(store_en), "Unknown store_en in store_check");

      if (rst) begin
         if (store_en) begin
            $display("[Commit][error] Should be nothing for reset");
            rval = FAIL;
         end
      end else if(store_en) begin
         chk_assert(unknown_check(store_type[0]), "Unknown store_type[0] in store_check");
         chk_assert(unknown_check(store_type[1]), "Unknown store_type[1] in store_check");
         for (int i = 0; i < 32; i++) begin
            chk_assert(unknown_check(store_addr[i]), "Unknown store_addr bit in store_check");
            chk_assert(unknown_check(store_value[i]), "Unknown store_value bit in store_check");
         end
	      if(commit[0].LS == 2'b01) begin
            if(commit[0].addr != store_addr) begin
	            $display("[Commit][error] Store address mismatch");
               rval = FAIL;
		      end else if(commit[0].value != store_value) begin
			    $display("[Commit][error] Store data mismatch");
             rval = FAIL;
             end else begin
			    num++;
				commit.delete(0);
			 end
		  end else if(commit[1].LS == 2'b01) begin
           if(commit[1].addr != store_addr) begin
	            $display("[Commit][error] Store address mismatch");
               rval = FAIL;
            end else if(commit[1].value != store_value) begin
			    $display("[Commit][error] Store data mismatch");
             rval = FAIL;
             end else begin
			    num++;
				commit.delete(1);
			 end		     
         end else begin
            $display("[Commit][error] Store should not be committed here");
            rval = FAIL;
         end
	   end
	   
	   commit_num += num;

      return rval;
	endfunction	

   function chkres_t ROBfull_check(bit rst, logic full);
      chkres_t rval = PASS;

      chk_assert(unknown_check(full), "Unknown ROB_full in ROBfull_check");

      if (rst) begin
         if (full) begin
            $display("[Commit][error] Should be nothing for reset");
            rval = FAIL;
         end
      end else if (full) begin
         if (env.dbg_msg) $display("[dbg] ROBfull: commit.size() = %d", commit.size());
         if (last_cmt_size < 28) begin
            $display("[Commit][error] ROB_full when not full");
            rval = FAIL;
         end
      end else if (last_cmt_size > 30) begin
         $display("[Commit][error] No ROB_full when full");
         rval = FAIL;
      end

      last_cmt_size = commit.size();

      return rval;
   endfunction
	  
endclass

`endif
