//modified @ 12 18
module alu_sub #(parameter OPRAND_WIDTH = 32,
				 parameter OP_FUNC_WIDTH = 17,
				 parameter IMM_WIDTH = 12
				 //17-bit structure [31:25] 7 bits [14:12] 3 bits [6:0] 7 bits
				 )
					(
						input [OPRAND_WIDTH-1:0] oprand1_i, oprand2_i,
						input [OP_FUNC_WIDTH-1:0] op_func_i,
						output logic [OPRAND_WIDTH-1:0] result_o
					);
					
//S_type
parameter BEQ = 17'bxxxxxxx_000_1100011,//branch =
		  BNE = 17'bxxxxxxx_001_1100011,//branch !=
		  BLT = 17'bxxxxxxx_100_1100011,//branch <
		  BGE = 17'bxxxxxxx_101_1100011,//branch >=
		  SB = 17'bxxxxxxx_000_0100011,
		  SH = 17'bxxxxxxx_001_0100011,//store halfword
		  SW = 17'bxxxxxxx_010_0100011,
//I_type
		  LB = 17'bxxxxxxx_000_0000011,
		  LH = 17'bxxxxxxx_001_0000011,//load halfword
          LW = 17'bxxxxxxx_010_0000011,  
		  LBU = 17'bxxxxxxx_100_0000011, 
		  LHU = 17'bxxxxxxx_101_0000011, 
		  ADDI = 17'bxxxxxxx_000_0010011,//add immediate
		  SLTI = 17'bxxxxxxx_010_0010011,//set < immediate
		  XORI = 17'bxxxxxxx_100_0010011,//xor immediate
		  ORI = 17'bxxxxxxx_110_0010011,//or immediate
		  ANDI = 17'bxxxxxxx_111_0010011,//and immediate
		  SLLI = 17'b0000000_001_0010011,//shift left immediate
		  SRLI = 17'b0000000_101_0010011,//shift right immediate
		  SRAI = 17'b0100000_101_0010011,//shift right arith imm 
//R_type
		  ADD = 17'b0000000_000_0110011,//
		  SUB = 17'b0100000_000_0110011,//		
		  SLL = 17'b0000000_001_0110011,//shift left
		  SLT = 17'b0000000_010_0110011,//set <
		  XOR = 17'b0000000_100_0110011,//
		  SRL = 17'b0000000_101_0110011,//shift right
		  SRA = 17'b0100000_101_0110011,//shift right arith
		  OR = 17'b0000000_110_0110011,//
		  AND = 17'b0000000_111_0110011,//
//U_type
		  JAL = 17'bxxxxxxx_xxx_1101111,//jump and link
		  JR = 17'bxxxxxxx_xxx_1100111;//jr $ra //self-defined
        
logic [OPRAND_WIDTH-1:0] oprand1, oprand2;
logic res;
		  
		  
reg signed [31:0] oprand11_i, oprand12_i;

assign oprand11_i = oprand1_i;
assign oprand12_i = oprand2_i;
		  
always_comb begin
	casex(op_func_i)
	//R_type
		ADD: begin
				result_o = oprand11_i + oprand12_i;
			 end
			 
		SUB: begin
					result_o = oprand11_i - oprand12_i;
			 end
		
		SLL,SLLI: begin
		        result_o = oprand1_i << oprand2_i[4:0];//see page 14
			 end
			 
		SLT: begin
				oprand1 = oprand1_i;
				oprand2 = oprand2_i;
				result_o = {{(OPRAND_WIDTH-1){'0}},res};
			 end
			 
		XOR: begin
		        result_o = oprand1_i ^ oprand2_i;
			 end
			 
		SRL,SRLI: begin
		        result_o = oprand1_i >> oprand2_i[4:0];//see page 14
			 end
		
		SRA: begin
              //logic [OPRAND_WIDTH-1:0] temp1;
			  //logic [$clog2(OPRAND_WIDTH)-1:0] temp2;
              //temp1 = oprand1_i>>oprand2_i[4:0];
			  //temp2 = OPRAND_WIDTH - oprand2_i[4:0];
              //result_o = {{oprand1_i[OPRAND_WIDTH-1]>>oprand2_i[4:0]}, {temp1 & ('1 >> temp2) }};//????????
			  result_o = oprand11_i >>> oprand2_i[4:0];
			 end
		SRAI: begin
              //logic [OPRAND_WIDTH-1:0] temp1;
			  //logic [$clog2(OPRAND_WIDTH)-1:0] temp2;
              //temp1 = oprand1_i>>oprand2_i[4:0];
			  //temp2 = OPRAND_WIDTH - oprand2_i[4:0];
              //result_o = {{oprand1_i[OPRAND_WIDTH-1]>>oprand2_i[4:0]}, {temp1 & ('1 >> temp2) }};//????????
			  result_o = oprand11_i >>> oprand2_i[4:0];
			 end
		
		OR: begin
		        result_o = oprand1_i | oprand2_i;
			 end
			 
		AND: begin
		        result_o = oprand1_i & oprand2_i;
			 end
			 
	//I_type with Imm signed extension	//imm always oprand2_i
		ADDI:begin
				result_o = oprand1_i + {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
			 end
			 
		SLTI: begin
				oprand1 = oprand1_i;
				oprand2 = {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
				result_o = {{(OPRAND_WIDTH-1){'0}},res};
			 end
			 
		XORI: begin
		        result_o = oprand1_i ^ {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
			 end
			 
		ORI: begin
		        result_o = oprand1_i | {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
			 end
			 
		ANDI: begin
		        result_o = oprand1_i & {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
			 end
			 
		LB,LH,LW,LBU,LHU,SH,SB,SW: begin
				result_o = oprand11_i + {{20{oprand2_i[IMM_WIDTH-1]}},oprand2_i[IMM_WIDTH-1:0]};
			 end
			 
		
	//S_type 
		//we assume all branch instruction's step is always the same and predefined (we don't have the ALU only for calculate NPC) 
		
		BEQ: begin
		        result_o = (oprand1_i == oprand2_i);//here result_o is not a rd, since this type doesn't have. We consider result_o as a flag bit back to ROB
			 end
		
		BNE: begin
				result_o = (oprand1_i != oprand2_i);
			 end
		
		BLT: begin
				oprand1 = oprand1_i;
				oprand2 = oprand2_i;
		        result_o = {{(OPRAND_WIDTH-1){'0}},res};
			 end
		
		BGE: begin
				oprand1 = oprand1_i;
				oprand2 = oprand2_i;
		        result_o = {{(OPRAND_WIDTH-1){'0}},!res};
			 end
			 
		JR: begin
				//do nothing 
			end
		//U_type
		JAL: begin
				result_o = oprand1_i + 1; //rd = PC + 4 for this instruction, we set oprand1 as PC, 1 is a virtual PC
			 end
		
		
          default: ;//$display("Wrong opcode and function : %b", op_func_i);
	endcase
end

		//assign oprand1 = oprand1_i;
		//assign oprand2 = oprand2_i;
//comparator 
    comparator_signed #(.DATA_WIDTH(OPRAND_WIDTH)) comp_less
						(
						 .oprand1_i(oprand1),.oprand2_i(oprand2),
						 .res_o(res) //set 1 if rs1 < rs2, otherwise
						);

endmodule
