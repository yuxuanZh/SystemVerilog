/****
 * The unit of Instruction decoder
 *  - 
 */
//`include "ifc_dec_rf.sv"
//`include "ifc_rob_dec.sv"
 
module insdec #(parameter INSTR_WIDTH = 32,
		 parameter PC_WIDTH = 32,
		 parameter REGNAME_WIDTH = 5,
		 parameter OP_WIDTH = 7)
				(
					input logic [INSTR_WIDTH-1:0] instruction1_i,
					input logic ins1_valid_i,
					input logic [PC_WIDTH-1:0] PC1_i,
					input logic [INSTR_WIDTH-1:0] instruction2_i,
					input logic ins2_valid_i,
					input logic [PC_WIDTH-1:0] PC2_i,
					ifc_dec_rf.dec rf,
					ifc_rob_dec.dec rob );
	
	//logic [6:0] opcode_type;			
	parameter R_TYPE_OP = 7'b0110011;
	parameter I_TYPE_OP = 7'b00x0011;
	parameter S_TYPE_OP = 7'bx100011;
	parameter U_TYPE_OP = 7'b110x111;
	parameter JR = {7'b1100111}; //JR special U
			  
	//read to ROB
	assign rob.ins1_valid = ins1_valid_i;//check if NOP also
	assign rob.ins2_valid = ins2_valid_i;
	
	assign rob.ins1 = rob.ins1_valid ? instruction1_i : {INSTR_WIDTH{'0}};
	assign rob.ins2 = rob.ins2_valid ? instruction2_i : {INSTR_WIDTH{'0}};
	assign rob.PC1 = rob.ins1_valid ? PC1_i : {PC_WIDTH{'0}};
	assign rob.PC2 = rob.ins2_valid ? PC2_i : {PC_WIDTH{'0}};

	always_comb begin 
	if(ins1_valid_i)
	casex(instruction1_i[OP_WIDTH-1:0]) 
	R_TYPE_OP: begin
				rf.write1_addr = instruction1_i[11:7];
				rf.read11_addr = instruction1_i[19:15];
				rf.read12_addr = instruction1_i[24:20];
				
				rf.write1_en = '1;
				rf.read11_en = '1;
				rf.read12_en = '1;
			   end 
			   
	I_TYPE_OP: begin
				rf.write1_addr = instruction1_i[11:7];
				rf.read11_addr = instruction1_i[19:15];
				rf.read12_addr = {REGNAME_WIDTH{'0}};
				
				rf.write1_en = '1;
				rf.read11_en = '1;
				rf.read12_en = '0;
			   end 

	S_TYPE_OP: begin
				rf.write1_addr = {REGNAME_WIDTH{'0}};
				rf.read11_addr = instruction1_i[19:15];
				rf.read12_addr = instruction1_i[24:20];
				
				rf.write1_en = '0;
				rf.read11_en = '1;
				rf.read12_en = '1;
			   end 
                
	U_TYPE_OP: begin
				if (instruction1_i[OP_WIDTH-1:0] == JR) begin
					rf.write1_addr = {REGNAME_WIDTH{'0}};
					rf.read11_addr = {REGNAME_WIDTH{'0}};//JR
					rf.read12_addr = {REGNAME_WIDTH{'0}};
					rf.write1_en = '0;
					rf.read11_en = '1;
					rf.read12_en = '0;
				end
				else begin
				//read data address and write *valid* address
				rf.write1_addr = instruction1_i[11:7];
				rf.read11_addr = {REGNAME_WIDTH{'0}};
				rf.read12_addr = {REGNAME_WIDTH{'0}};
				//read data control and write *valid* control
				rf.write1_en = '1;
				rf.read11_en = '0;
				rf.read12_en = '0;
				end
			   end	
            default: ;//$display("Wrong opcode and function : %b", instruction1_i[OP_WIDTH-1:0]);
	endcase
	
	else
		 begin 
			//read data address and write *valid* address
			rf.write1_addr = {REGNAME_WIDTH{'0}};
			rf.read11_addr = {REGNAME_WIDTH{'0}};
			rf.read12_addr = {REGNAME_WIDTH{'0}};
			//read data control and write *valid* control
			rf.write1_en = '0;
			rf.read11_en = '0;
			rf.read12_en = '0;
		 end
	end	
	
	always_comb begin 
	if(ins2_valid_i)
	casex(instruction2_i[OP_WIDTH-1:0]) 
	R_TYPE_OP: begin
				rf.write2_addr = instruction2_i[11:7];
				rf.read21_addr = instruction2_i[19:15];
				rf.read22_addr = instruction2_i[24:20];
				
				rf.write2_en = '1;
				rf.read21_en = '1;
				rf.read22_en = '1;
			   end 
			   
	I_TYPE_OP: begin
				rf.write2_addr = instruction2_i[11:7];
				rf.read21_addr = instruction2_i[19:15];
				rf.read22_addr = {REGNAME_WIDTH{'0}};
				
				rf.write2_en = '1;
				rf.read21_en = '1;
				rf.read22_en = '0;
			   end 

	S_TYPE_OP: begin
				rf.write2_addr = {REGNAME_WIDTH{'0}};
				rf.read21_addr = instruction2_i[19:15];
				rf.read22_addr = instruction2_i[24:20];
				
				rf.write2_en = '0;
				rf.read21_en = '1;
				rf.read22_en = '1;
			   end 
                
	U_TYPE_OP: begin
				if (instruction1_i[OP_WIDTH-1:0] == JR) begin
					rf.write2_addr = {REGNAME_WIDTH{'0}};
					rf.read21_addr = {REGNAME_WIDTH{'0}};//JR
					rf.read22_addr = {REGNAME_WIDTH{'0}};
					rf.write2_en = '0;
					rf.read21_en = '1;
					rf.read22_en = '0;
				end
				else begin
				//read data address and write *valid* address
				rf.write2_addr = instruction2_i[11:7];
				rf.read21_addr = {REGNAME_WIDTH{'0}};
				rf.read22_addr = {REGNAME_WIDTH{'0}};
				//read data control and write *valid* control
				rf.write2_en = '1;
				rf.read21_en = '0;
				rf.read22_en = '0;
				end
			   end
               
            default: ;//$display("Wrong opcode and function : %b", instruction2_i[OP_WIDTH-1:0]);
	endcase
	
	else
		 begin 
			//read data address and write *valid* address
			rf.write2_addr = {REGNAME_WIDTH{'0}};
			rf.read21_addr = {REGNAME_WIDTH{'0}};
			rf.read22_addr = {REGNAME_WIDTH{'0}};
			//read data control and write *valid* control
			rf.write2_en = '0;
			rf.read21_en = '0;
			rf.read22_en = '0;
		 end
	end	
	
endmodule
