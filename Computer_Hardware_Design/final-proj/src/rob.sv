//modified by Yuxuan @ 12/11
`include "src/sub_units/head_tail_control.sv"
`include "src/sub_units/ram_2r_2w.sv"
`include "src/sub_units/ram_2r_4w.sv"
`include "src/sub_units/ram_3r_2w.sv"
`include "src/sub_units/ff_2r_2w.sv"
`include "src/sub_units/ff_1r_1w.sv"
`include "src/sub_units/ff_2r_6w.sv"
`include "src/sub_units/pencoder.sv"
`include "src/sub_units/pc_alu.sv"
//`include "src/sub_units/precoder.sv"

module rob
	   #(parameter ROB_DEPTH = 32, parameter OP_WIDTH = 7, 
		 parameter FUNC_WIDTH = 10, parameter OPRAND_WIDTH = 32,
		 parameter IMM_WIDTH = 12, parameter REGNAME_WIDTH = 5,
		 parameter ENTRY_WIDTH = 5, parameter INS_WIDTH = 32,
		 parameter PC_WIDTH = 32)
  (input clk, rst,
   ifc_rob_dec.rob dec,
   ifc_rob_rf.rob rf,
   ifc_rob_alu.rob alu,
   ifc_rob_lsq.rob lsq,
   output logic             ROB_full_o,
   output logic [PC_WIDTH-1:0] jump_PC_o,
   output logic             jump_en_o,
   output logic [PC_WIDTH-1:0] branch_PC_o,
   output logic             branch_en_o,
   output logic             flush_en_o,//PC of instruction causing flush
   output logic [PC_WIDTH-1:0] flush_PC_o//+flush_valid_i flush_entry_i from LSQ
   );
   

parameter R_type = 7'b0110011, I_type2 =  7'b0010011;//OP 

//S_type = 7'bx100011, = STORE || BRANCH
//I_type = 7'b00x0011, = LOAD || I_type2
//U_type = 7'b110x111 = JUMP || JR

parameter BRANCH = 7'b1100011, JUMP = 7'b1101111, JR = 7'b1100111, STORE = 7'b0100011, LOAD = 7'b0000011;//OP
parameter LB = 10'b000_0000011, LH = 10'b001_0000011, LW = 10'b010_0000011, 
          LBU = 10'b100_0000011, LHU = 10'b101_0000011,
		  SB = 10'b000_0100011, SH = 10'b001_0100011, SW = 10'b010_0100011;//OP + funct3

//head & tail
logic [4:0] head, head_2, tail, tail_2;
		  
logic [31:0] v_data1, v_data2, v_data1_o, v_data2_o;
logic [5:0] search_entry1, search_entry2;

logic [4:0] issue_entry1, issue_entry2, issue_entry1_ff, issue_entry2_ff;
logic issue_valid1, issue_valid2, issue_valid1_ff, issue_valid2_ff;

//ALU
logic [31:0] operand11_o, operand12_o, operand21_o, operand22_o;
logic [16:0] op_func1_o, op_func2_o;

//PC-ALU
logic [31:0] pc_alu_operand1, pc_alu_operand2, pc_alu_result;

//to LSQ
//IO
logic [REGNAME_WIDTH-1:0] addr_entry_o;
logic addr_valid_o;
logic [OPRAND_WIDTH-1:0] store_data_o;

logic [REGNAME_WIDTH-1:0] target_bus1, target_bus1_ff, target_bus2, target_bus2_ff;
logic [ROB_DEPTH-1:0] index_tail, index_tail_2, index_issue_1, index_issue_2;

logic [PC_WIDTH-1:0] ins1_pc_i, ins2_pc_i;
logic ins1_valid_i, ins2_valid_i;

logic read11_ready_i, read12_ready_i, read21_ready_i, read22_ready_i;
logic [OPRAND_WIDTH-1:0] read11_data_i, read12_data_i, read21_data_i, read22_data_i;
logic read11_valid_bit_i, read12_valid_bit_i, read21_valid_bit_i, read22_valid_bit_i;

logic [INS_WIDTH-1:0] ins1_i, ins2_i;
logic [OP_WIDTH-1:0] op1, op2; 

logic [REGNAME_WIDTH-1:0] target1, target2;
logic [FUNC_WIDTH-1:0] func1, func2;
logic [REGNAME_WIDTH-1:0] ins1_src0, ins2_src0, ins1_src1, ins2_src1;

logic imm1_valid, imm2_valid;
logic [IMM_WIDTH-1:0] imm1_data, imm2_data;

logic ls_valid1_o, ls_valid2_o;
logic ls_valid11_o, ls_valid12_o;
logic [2:0] ls_type1_o, ls_type2_o;
logic [REGNAME_WIDTH-1:0] ls_entry1_i, ls_entry2_i;
logic [REGNAME_WIDTH-1:0] ls_entry11_i, ls_entry12_i;

logic [OPRAND_WIDTH-1:0] result1_i, result2_i;
logic [OPRAND_WIDTH-1:0] result_bus1_ff, result_bus2_ff;//delay result for one cycle
logic [OPRAND_WIDTH-1:0] result_r1_data, result_r2_data; 
logic [PC_WIDTH-1:0] PC_data1, PC_data2, PC_data3;

logic [ROB_DEPTH-1:0] e_data;
logic [ROB_DEPTH-1:0] [OP_WIDTH-1:0] op_data;
logic [ROB_DEPTH-1:0] [FUNC_WIDTH-1:0] func_data;
logic [ROB_DEPTH-1:0] [IMM_WIDTH-1:0] imm_data;
logic [ROB_DEPTH-1:0] [REGNAME_WIDTH-1:0] target_data;
logic [ROB_DEPTH-1:0] [REGNAME_WIDTH-1:0] src0_data;
logic [ROB_DEPTH-1:0] [REGNAME_WIDTH-1:0] src1_data;
logic [ROB_DEPTH-1:0] [ENTRY_WIDTH-1:0] entry;
logic [ROB_DEPTH-1:0] v0_data, v1_data;
logic [ROB_DEPTH-1:0] [OPRAND_WIDTH-1:0] arg0_data, arg1_data;

//done ram
logic d_r1_valid, d_r2_valid;//read valid
logic d_r1_en, d_r2_en;//read en
logic d_r1_data, d_r2_data;//read data

//WB_data
logic WB_en1_o, WB_en2_o;
logic [REGNAME_WIDTH-1:0] WB_target1_o, WB_target2_o;
logic [OPRAND_WIDTH-1:0] WB_data1_o, WB_data2_o;

//broadcast enable
logic [ROB_DEPTH-1:0] bcast_issue11, bcast_issue12, bcast_issue21, bcast_issue22;
logic [ROB_DEPTH-1:0] bcast_commit11, bcast_commit12, bcast_commit21, bcast_commit22;

//commit
logic [1:0] comcnt;

//commit lsq
logic [OPRAND_WIDTH-1:0] load_data_i;
logic [REGNAME_WIDTH-1:0] load_commit_entry_o, store_commit_entry_o;
logic load_commit_valid_o, store_commit_valid_o;

//flush
logic entry_search_valid;
logic [REGNAME_WIDTH-1:0] entry_search_index;
logic [4:0] tail_temp1, tail_temp2;
logic flush_valid_i;
logic [REGNAME_WIDTH-1:0] flush_entry_i;
logic [REGNAME_WIDTH-1:0] flush_index;

//new
logic [ROB_DEPTH-1:0] [OP_WIDTH-1:0] op_data_ff;

assign ins1_i = dec.ins1;
assign ins2_i = dec.ins2;
assign ins1_valid_i = dec.ins1_valid;
assign ins2_valid_i = dec.ins2_valid;
//assign ins1_pc_i = dec.PC1;//define below
//assign ins2_pc_i = dec.PC2;

assign read11_valid_bit_i = rf.read11_valid_bit;
assign read12_valid_bit_i = rf.read12_valid_bit;
assign read21_valid_bit_i = rf.read21_valid_bit;
assign read22_valid_bit_i = rf.read22_valid_bit;
assign read11_ready_i = rf.read11_ready;
assign read12_ready_i = rf.read12_ready;
assign read21_ready_i = rf.read21_ready;
assign read22_ready_i = rf.read22_ready;
assign read11_data_i = rf.read11_data;
assign read12_data_i = rf.read12_data;
assign read21_data_i = rf.read21_data;
assign read22_data_i = rf.read22_data;
assign rf.WB_en1 = WB_en1_o;
assign rf.WB_en2 = WB_en2_o;
assign rf.WB_target1 = WB_target1_o;
assign rf.WB_target2 = WB_target2_o;
assign rf.WB_data1 = WB_data1_o;
assign rf.WB_data2 = WB_data2_o;

assign result1_i = alu.result1;
assign result2_i = alu.result2;
assign alu.operand11 = operand11_o;
assign alu.operand12 = operand12_o;
assign alu.operand21 = operand21_o;
assign alu.operand22 = operand22_o;
assign alu.op_func1 = op_func1_o;
assign alu.op_func2 = op_func2_o;

assign ls_entry1_i = lsq.ls_entry1;
assign ls_entry2_i = lsq.ls_entry2;
assign load_data_i = lsq.load_data;
//assign load_data_valid_i = lsq.load_data_valid;//?????
assign flush_valid_i = lsq.flush_valid;
assign flush_entry_i = lsq.flush_valid;
assign lsq.ls_type1 = ls_type1_o;
assign lsq.ls_type2 = ls_type2_o;
assign lsq.ls_valid1 = ls_valid1_o;
assign lsq.ls_valid2 = ls_valid2_o;
assign lsq.addr_entry = addr_entry_o;
assign lsq.addr_valid = addr_valid_o;
assign lsq.load_commit_entry = load_commit_entry_o;
assign lsq.load_commit_valid = load_commit_valid_o;
assign lsq.store_data = store_data_o;
assign lsq.store_commit_entry = store_commit_entry_o;
assign lsq.store_commit_valid = store_commit_valid_o;

//*************************************************ROB Flush****************************************************

head_tail_control #(.INDEX_WIDTH(REGNAME_WIDTH)) head_tail_control
	(
	.clk, .rst,
	.head_i(head), .tail_i(tail),
	.comcnt_i(comcnt),
	.tail_branch_jump_i(tail_temp1), .tail_lsq_flush_i(tail_temp2),
	.ins1_valid_i, .ins2_valid_i,
	.head_o(head), .tail_o(tail),
	.full_o(ROB_full_o),
	.flush_index_o(flush_index)//index in ROB which causes flush
	);

assign flush_en_o = flush_valid_i || branch_en_o || jump_en_o;
assign flush_PC_o = flush_en_o ? PC_data3 : {PC_WIDTH{'0}};


//search branch/jump instruction index 
always_comb begin
	if(branch_en_o)//branch_en here means misprediction , because in TB we always give PC+1
		if(op_data[issue_entry1] == BRANCH)//1st or 2nd instruction is BRANCH
			tail_temp1 = issue_entry1;
		else
			tail_temp1 = issue_entry2;
	else if(jump_en_o)
		if(op_data[issue_entry1] == JUMP)
			tail_temp1 = issue_entry1;
		else
			tail_temp1 = issue_entry2;
	else
			tail_temp1 = tail;
end

//search entry when LSQ flush
always_comb begin
	if(flush_valid_i)
		for(int iter = 0;iter < 31; iter++) begin
		 int i;
		 if(iter + head + '1 > 5'd31) i = iter + head + '1 - 6'd32;
		 else i = iter + head + '1;
		 //end of search
		 //if(i == tail) break;//?
		 
		 if(flush_entry_i == entry[i]) begin
			 entry_search_index = i;
			 entry_search_valid = '1;
			break;
		 end
		end
	else begin
			entry_search_valid = '0;
			entry_search_index = 5'd0;
		end
end

always_comb begin
if(entry_search_valid)
	tail_temp2 = entry_search_index;
else
	tail_temp2 = tail;
end

//*************************************************ROB Enqueue****************************************************
//integrate v0 v1 OP func arg0 arg1 imm target entry  src0 src1 FFs   E??? PC??

//v0 v1 arg0 arg1 6w ???
//enqueue PC
ram_3r_2w  #(.OPRAND_WIDTH(OPRAND_WIDTH),
			 .ARRAY_ENTRY(ROB_DEPTH),
			 .REGNAME_WIDTH(REGNAME_WIDTH)) ram_PC
	(.clk,
	 .rst,
	 .read1_en_i('1), .read2_en_i('1), .read3_en_i(flush_en_o),//used to read flush PC
	 .read1_addr_i(issue_entry1), .read2_addr_i(issue_entry2), .read3_addr_i(flush_index),
	 .write1_en_i(ins1_valid_i), .write2_en_i(ins2_valid_i),
	 .write1_addr_i(tail), .write2_addr_i(tail_2),
	 .write1_data_i(ins1_pc_i), .write2_data_i(ins2_pc_i),
	 .read1_data_o(PC_data1), .read2_data_o(PC_data2), .read3_data_o(PC_data3),
	 .read1_ready_o(), .read2_ready_o(), .read3_ready_o()
	 );

//enqueue E?

//enqueue reset *Done* flushed instructions 
//don't care *Result* data

//enqueue to FF arrays
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_tail
				    (.index_i(tail),
			         .index_depth_o(index_tail)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_tail_2
				    (.index_i(tail_2),
			         .index_depth_o(index_tail_2)
					 );

decoder #(.WIDTH(REGNAME_WIDTH)) decoder_issue_entry1
				    (.index_i(issue_entry1),
			         .index_depth_o(index_issue_1)
					 );					 

decoder #(.WIDTH(REGNAME_WIDTH)) decoder_issue_entry2
				    (.index_i(issue_entry2),
			         .index_depth_o(index_issue_2)
					 );		
					 

generate
 for (genvar i = 0; i < ROB_DEPTH; i++) begin
  ff_2r_4w #(.DATA_WIDTH(1)) ff_execution //diff with Done bit. 
	(.clk, .rst,
	.write11_en_i(issue_valid1 && index_issue_1[i]),.write12_en_i(issue_valid2 && index_issue_2[i]),//E shouldn't have 1 cycle delay when write. It determine issue
	.write21_en_i(ins1_valid_i && index_tail[i]),.write22_en_i(ins2_valid_i && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data11_i('1), .data12_i('1), .data21_i('0), .data22_i('0), //write "0" when enqueue, way to flush
	.data1_o(e_data[i]), .data2_o()
   );
 
 ff_2r_2w #(.DATA_WIDTH(OP_WIDTH)) ff_OP//have to be 2w, no addr contention but data
   (
	.clk, .rst,
	.write1_en_i(ins1_valid_i && index_tail[i]),.write2_en_i(ins2_valid_i && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(op1), .data2_i(op2), 
	.data1_o(op_data[i]), .data2_o()
   );    
   
 ff_2r_2w #(.DATA_WIDTH(FUNC_WIDTH)) ff_func
   (
	.clk, .rst,
	.write1_en_i(ins1_valid_i && (op1 != JUMP && op1 != JR) && index_tail[i]), 
	.write2_en_i(ins2_valid_i && (op2 != JUMP && op2 != JR) && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(func1), .data2_i(func2), 
	.data1_o(func_data[i]), .data2_o()
   ); 
   
  ff_2r_2w #(.DATA_WIDTH(IMM_WIDTH)) ff_imm
   (
	.clk, .rst,
	.write1_en_i(imm1_valid && index_tail[i]), .write2_en_i(imm2_valid && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(imm1_data), .data2_i(imm2_data), 
	.data1_o(imm_data[i]), .data2_o()
   );
   
    ff_2r_2w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_target
   (
	.clk, .rst,
	.write1_en_i(ins1_valid_i && (op1 != STORE && op1 != BRANCH && op1 != JR) && index_tail[i]), 
	.write2_en_i(ins2_valid_i && (op2 != STORE && op2 != BRANCH && op2 != JR) && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(target1), .data2_i(target2), 
	.data1_o(target_data[i]), .data2_o()
   );
   
   ff_2r_2w #(.DATA_WIDTH(ENTRY_WIDTH)) ff_lsq_entry
   (
	.clk, .rst,
	.write1_en_i(ls_valid11_o && index_tail[i]), 
	.write2_en_i(ls_valid12_o && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(ls_entry11_i), .data2_i(ls_entry12_i), 
	.data1_o(entry[i]), .data2_o()
   );
   
   ff_2r_2w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_src0
   (
	.clk, .rst,
	.write1_en_i(ins1_valid_i && (op1 != JUMP) && index_tail[i]), //consider JR as U_type with diff opcode, need Rs1
	.write2_en_i(ins2_valid_i && (op2 != JUMP) && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(ins1_src0), .data2_i(ins2_src0), 
	.data1_o(src0_data[i]), .data2_o()
   );
   
   ff_2r_2w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_src1
   (
	.clk, .rst,
	.write1_en_i(ins1_valid_i && (op1 != JUMP && op1 != JR && op1 != I_type2 && op1 != LOAD) && index_tail[i]), 
	.write2_en_i(ins2_valid_i && (op2 != JUMP && op2 != JR && op2 != I_type2 && op2 != LOAD) && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(ins1_src1), .data2_i(ins2_src1), 
	.data1_o(src1_data[i]), .data2_o()
   );   
   
 end
endgenerate

//result data ram after delay on ALU to ROB forward
ram_2r_2w #(.OPRAND_WIDTH(OPRAND_WIDTH),
			 .ARRAY_ENTRY(ROB_DEPTH),
			  .REGNAME_WIDTH(REGNAME_WIDTH)) ram_result_2r_2w
	(.clk,
	 .rst,
	 .read1_en_i('1), .read2_en_i('1),
	 .read1_addr_i(head), .read2_addr_i(head_2),                                            
	 .write1_en_i(issue_valid1_ff), .write2_en_i(issue_valid2_ff),  //  result_cam_w1_en = issue1_valid;
	 .write1_addr_i(issue_entry1_ff), .write2_addr_i(issue_entry2_ff), //result_cam_w1_index = match1_entry???
	 .write1_data_i(result_bus1_ff), .write2_data_i(result_bus2_ff), //result_cam_w1_data = result_bus1;??
	 .read1_data_o(result_r1_data), .read2_data_o(result_r2_data),
	 .read1_ready_o(), .read2_ready_o()
	 );
	 

//done bit ram commit flag
ram_2r_4w #(.OPRAND_WIDTH(1),
			 .ARRAY_ENTRY(ROB_DEPTH),
			  .REGNAME_WIDTH(REGNAME_WIDTH)) ram_done_2r_4w
	(.clk,
	 .rst,
	 .read1_en_i(d_r1_en), .read2_en_i(d_r2_en),
	 .read1_addr_i(head), .read2_addr_i(head_2),                                            
	 .write11_en_i(issue_valid1_ff), .write12_en_i(issue_valid2_ff),  //issue_valid need one cycle delay????
	 .write21_en_i(ins1_valid_i ), .write22_en_i(ins2_valid_i ),//write "0" when queue at tail
	 .write11_addr_i(issue_entry1_ff ), .write12_addr_i(issue_entry2_ff ),//??
	 .write21_addr_i(tail), .write22_addr_i(tail_2),
	 .write11_data_i('1), .write12_data_i('1),
	 .write21_data_i('0), .write22_data_i('0),//no contention //enqueue reset done bit
	 .read1_data_o(d_r1_data), .read2_data_o(d_r2_data),//only commit 2 instruction at most 
	 .read1_ready_o(d_r1_valid), .read2_ready_o(d_r2_valid)
	 );
	 
//tail_2
//always_comb begin
//	if(tail + '1 > 5'd31) tail_2 = tail + '1 - 6'd32;
//	else tail_2 = tail + '1;
//end
    assign tail_2 = tail + 5'd1;

//parse instruction roughly
always_comb begin
	if(ins1_valid_i) begin
		op1 = ins1_i[6:0];
		target1 = ins1_i[11:7];
		func1 = {ins1_i[31:25],ins1_i[14:12]};
		ins1_src0 = ins1_i[19:15];
		ins1_src1 = ins1_i[24:20];
		ins1_pc_i = dec.PC1;
	end
	else begin
		op1 = 7'd0;
		target1 = 5'd0;
		func1 = 10'd0;
		ins1_src0 = 5'd0;
		ins1_src1 = 5'd0;
		ins1_pc_i = 32'd0;
	end

	if(ins2_valid_i) begin
		op2 = ins2_i[6:0];
		target2 = ins2_i[11:7];
		func2 = {ins2_i[31:25],ins2_i[14:12]};
		ins2_src0 = ins2_i[19:15];
		ins2_src1 = ins2_i[24:20];
		ins2_pc_i = dec.PC2;
	end
	else begin
		op2 = 7'd0;
		target2 = 5'd0;
		func2 = 10'd0;
		ins2_src0 = 5'd0;
		ins2_src1 = 5'd0;
		ins2_pc_i = 32'd0;
	end
end

//parse Imm
always_comb begin
	if(ins1_valid_i)
		casex (op1)
			R_type:	begin 
						imm1_valid = '0;
						imm1_data = 12'd0;
					end
			I_type2,LOAD: begin
						imm1_valid = '1;
						imm1_data = ins1_i[31:20];
					end
			BRANCH,STORE:	begin 
						imm1_valid = '1;
						imm1_data = {ins1_i[31:25], ins1_i[11:7]};
					end
			JUMP,JR:	begin 
						imm1_valid = '1;
						imm1_data = ins1_i[31:20];
					end
			default: begin
						imm1_valid = '0;
						imm1_data = 12'd0;
					end
		endcase
	else begin
			imm1_valid = '0;
			imm1_data = 12'd0;
		 end
		 
	if(ins2_valid_i)
		casex (op2)
			R_type:	begin 
						imm2_valid = '0;
						imm2_data = 12'd0;
					end
			I_type2,LOAD: begin
						imm2_valid = '1;
						imm2_data = ins2_i[31:20];
					end
			BRANCH,STORE:	begin 
						imm2_valid = '1;
						imm2_data = {ins2_i[31:25], ins2_i[11:7]};
					end
			JUMP,JR:	begin 
						imm2_valid = '1;
						imm2_data = ins2_i[31:20];
					end
			default: begin
						imm2_valid = '0;
						imm2_data = 12'd0;
					end
		endcase
	else begin
			imm2_valid = '0;
			imm2_data = 12'd0;
		 end 	
end//always




always_comb begin
	if(ins1_valid_i && (op1 == LOAD) || (op1 == STORE)) begin
	   ls_entry11_i = ls_entry1_i;
	   ls_valid11_o = 1;
	   if(ins2_valid_i && (op2 == LOAD) || (op2 == STORE)) begin
	      ls_valid12_o = 1;
          ls_entry12_i = ls_entry2_i;
	   end 
	   else begin
	      ls_valid12_o = 0;
          ls_entry12_i = '0;
	   end
	end else begin
	   ls_valid11_o = 0;
       ls_entry11_i = '0;	
	   if(ins2_valid_i && (op2 == LOAD) || (op2 == STORE)) begin
	      ls_valid12_o = 1;
          ls_entry12_i = ls_entry1_i;
	   end 
	   else begin
	      ls_valid12_o = 0;
          ls_entry12_i = '0;
	   end	   
	end
end


//parse memory instruction for LSQ
always_comb begin
	if(ins1_valid_i && (op1 == LOAD) || (op1 == STORE))
		case({func1[2:0], op1})
			LW: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b010;
				end
			LH,LHU: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b001;
				end
			LB,LBU: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b000;
				end
			SW: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b110;
				end
			SH: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b101;
				end
			SB: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b100;
				end
			default: begin
					ls_valid1_o = '0;
					ls_type1_o = 3'b111;
				end
		endcase
	else if (ins1_valid_i && ((op1 != LOAD) && (op1 != STORE)) && ins2_valid_i)
		case({func2[2:0], op2})
			LW: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b010;
				end
			LH,LHU: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b001;
				end
			LB,LBU: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b000;
				end
			SW: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b110;
				end
			SH: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b101;
				end
			SB: begin
					ls_valid1_o = '1;
					ls_type1_o = 3'b100;
				end
			default: begin
					ls_valid1_o = '0;
					ls_type1_o = 3'b111;
				end
		endcase
	else begin
		ls_valid1_o = '0;
		ls_type1_o = 3'b111;
	end

	if (ins2_valid_i && ls_valid1_o && ((op1 == LOAD) || (op1 == STORE)))
		case({func2[2:0], op2})
			LW: begin
					ls_valid2_o = '1;
					ls_type2_o = 3'b010;
				end
			LH,LHU: begin
					ls_valid2_o = '1;
					ls_type2_o = 3'b001;
				end
			LB,LBU: begin
					ls_valid2_o = '1;
					ls_type2_o = 3'b000;
				end
			SW: begin
					ls_valid2_o = '1;	
					ls_type2_o = 3'b110;
				end
			SH: begin
					ls_valid2_o = '1;
					ls_type2_o = 3'b101;
				end
			SB: begin
					ls_valid2_o = '1;
					ls_type2_o = 3'b100;
				end
			default: begin
					ls_valid2_o = '0;
					ls_type2_o = 3'b111;
				end
		endcase
	else begin
		ls_valid2_o = '0;
		ls_type2_o = 3'b111;
	end
end//always

//*************************************************ROB Issue****************************************************
//integrate v0 v1 OP func arg0 arg1 imm target entry  src0 src1 FFs   E??? PC??

ff_1r_1w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_target_bus1
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid1),//? 
	.read_en_i('1), 
    .data_i(target_bus1),
	.data_o(target_bus1_ff)
   );

ff_1r_1w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_target_bus2
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid2),//? 
	.read_en_i('1), 
    .data_i(target_bus2),
	.data_o(target_bus2_ff)
   );

ff_1r_1w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_issue_entry_bus1
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid1), //?
	.read_en_i('1), 
    .data_i(issue_entry1),
	.data_o(issue_entry1_ff)
   );
   
ff_1r_1w #(.DATA_WIDTH(REGNAME_WIDTH)) ff_issue_entry_bus2
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid2), //?
	.read_en_i('1), 
    .data_i(issue_entry2),
	.data_o(issue_entry2_ff)
   );
   
ff_1r_1w #(.DATA_WIDTH(1)) ff_issue_valid_bus1
   (
	.clk, 
	.rst,
	.write_en_i('1), //issue_valid1
	.read_en_i('1), 
    .data_i(issue_valid1),
	.data_o(issue_valid1_ff)
   );
   
ff_1r_1w #(.DATA_WIDTH(1)) ff_issue_valid_bus2
   (
	.clk, 
	.rst,
	.write_en_i('1), //issue_valid2
	.read_en_i('1), 
    .data_i(issue_valid2),
	.data_o(issue_valid2_ff)
   );
   
ff_1r_1w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_result_bus1
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid1), //??
	.read_en_i('1), 
    .data_i(result1_i),
	.data_o(result_bus1_ff)
   );
   
ff_1r_1w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_result_bus2
   (
	.clk, 
	.rst,
	.write_en_i(issue_valid2), //?
	.read_en_i('1), 
    .data_i(result2_i),
	.data_o(result_bus2_ff)
   );
   
 
generate
for(genvar k=0; k<ROB_DEPTH; k++)
ff_1r_1w #(.DATA_WIDTH(OP_WIDTH)) ff_op_data_ff
(
	.clk, 
	.rst,
	.write_en_i('1), 
	.read_en_i('1), 
    .data_i(op_data[k]),
	.data_o(op_data_ff[k])
   );
endgenerate
   
   

pc_alu #(.DATA_WIDTH(OPRAND_WIDTH)) pc_alu
		(.pc_alu_operand1_i(pc_alu_operand1), .pc_alu_operand2_i(pc_alu_operand2), .pc_alu_result(pc_alu_result));
   
//search first
always_comb begin
	for (int iter = 0 ; iter < 32 ; iter++) begin//??30 or 31s
		logic [4:0] i;
		i = iter + head;

			
		if (((op_data[i] == R_type && v0_data[i] && v1_data[i]) ||
			((op_data[i] == I_type2 || op_data[i] == LOAD) && v0_data[i]) ||
			((op_data[i] == STORE || op_data[i] == BRANCH) && v0_data[i] && v1_data[i]) ||
			(op_data[i] == JR && v0_data[i])||
			 op_data[i] == JUMP) && !e_data[i]) //have not to be executed
			v_data1[iter] = 1;
		else v_data1[iter] = 0;
	end
end 	
//	pencoder #(.WIDTH(5)) priority_encoder1 (.search_valid_i(v_data1), .search_index_o(search_entry1));
//	precoder #(.WIDTH(5))  pre_encoder1 (.head(head), .search_valid_i(v_data1), .search_valid_o(v_data1_o));
    pencoder #(.WIDTH(6))  priority_encoder1 (.search_valid_i(v_data1), .search_index_o(search_entry1));

assign	issue_entry1 = search_entry1 + head;

logic [5:0] length1;
assign length1 = (tail >= head) ? tail - head : tail + 6'd32 - head;

always_comb begin
	if(search_entry1 < length1 && search_entry1[5] == 0)
		issue_valid1 = 1;
	else
		issue_valid1 = 0;
end

//	if(|v_data1 == '1) issue_valid1 = '1;//BUG??v_data1[0:iter]
//	else issue_valid1 = '0;

always_comb begin
	//priority data mapping
	//if(search_entry1 + head + '1 > 5'd31)  issue_entry1 = search_entry1 + head + '1 - 6'd32;
	//	else issue_entry1 = search_entry1 + head + 1;
	//issue found	
	
	//operand func & target to ALU
	if (issue_valid1 && op_data[issue_entry1] == R_type) begin
		operand11_o = arg0_data[issue_entry1];
        operand12_o = arg1_data[issue_entry1];
		op_func1_o = {func_data[issue_entry1], op_data[issue_entry1]};
		target_bus1 = target_data[issue_entry1];
		end
	else if (issue_valid1 && (op_data[issue_entry1] == I_type2 || op_data[issue_entry1] == LOAD)) begin
		operand11_o = arg0_data[issue_entry1];
        operand12_o = imm_data[issue_entry1];
		op_func1_o = {func_data[issue_entry1], op_data[issue_entry1]};
		target_bus1 = target_data[issue_entry1];
		end
	else if (issue_valid1 && (op_data[issue_entry1] == STORE || op_data[issue_entry1] == BRANCH)) begin
			if(op_data[issue_entry1] == BRANCH) begin
				operand11_o = arg0_data[issue_entry1];
				operand12_o = arg1_data[issue_entry1];
				op_func1_o = {func_data[issue_entry1], op_data[issue_entry1]};
				target_bus1 = 5'd0;
				end
			else begin
				operand11_o = arg0_data[issue_entry1];
				operand12_o = imm_data[issue_entry1];
				op_func1_o = {func_data[issue_entry1], op_data[issue_entry1]};
				target_bus1 = 5'd0;
				end
			end
	else if (issue_valid1 && op_data[issue_entry1] == JUMP) begin//jump
				operand11_o = PC_data1;
                operand12_o = 32'd1;
				op_func1_o = {func_data[issue_entry1], op_data[issue_entry1]};
				target_bus1 = target_data[issue_entry1];//reg0
				end
	else begin 	//JR?????
				operand11_o = 32'd0; 
                operand12_o = 32'd0;
				op_func1_o = 17'd0;
				target_bus1 = 5'd0;
		end
end

//search second
//
always_comb begin
	if(issue_valid1 == '1) begin
	 for(int iter=0; iter<32; iter++) begin//search next 30 at most 
		logic [4:0] i;
		i = iter + issue_entry1 + 5'd1;

		
		 if ((op_data[i] == R_type && v0_data[i] && v1_data[i]) || 
			(op_data[i] == I_type2 && v0_data[i]) || 
			(op_data[i] == LOAD && (op_data[issue_entry1] != LOAD && op_data[issue_entry1] != STORE) && v0_data[i]) ||
			(op_data[i] == BRANCH && op_data[issue_entry1] != BRANCH && op_data[issue_entry1] != JUMP && v0_data[i] && v1_data[i]) ||
			(op_data[i] == STORE &&  (op_data[issue_entry1] != LOAD && op_data[issue_entry1] != STORE) && v0_data[i] && v1_data[i]) ||
			(op_data[i] == JR && v0_data[i]) ||
			(op_data[i] == JUMP && op_data[issue_entry1] != BRANCH && op_data[issue_entry1] != JUMP) && 
			!e_data[i]) 
			v_data2[iter] = 1;		
		else v_data2[iter] = 0;
	 end
	end	
	else v_data2 = 32'd0;		
end

//pencoder #(.WIDTH(5)) priority_encoder2 (.search_valid_i(v_data2),.search_index_o(search_entry2));
//	precoder #(.WIDTH(5)) pre_encoder2      (.head(issue_entry1+5'd1), .search_valid_i(v_data2), .search_valid_o(v_data2_o));
    pencoder #(.WIDTH(6))  priority_encoder2 (.search_valid_i(v_data2), .search_index_o(search_entry2));

assign	issue_entry2 = search_entry2 + issue_entry1+5'd1;

logic [5:0] length2;
assign length2 = (tail >= issue_entry1+6'd1) ? tail - issue_entry1 - 6'd1 : tail + 6'd31 - issue_entry1;


always_comb begin
	if(search_entry2 < length2 && search_entry2[5] == 0)
		issue_valid2 = 1;
	else
		issue_valid2 = 0;
end

//	if(|v_data2 == '1) issue_valid2 = '1;
//	else issue_valid2 = '0;
//assign operand & opcode to ALU
always_comb begin
	
	//ring index mapping
	//if (search_entry2 + head + 5'd1 > 6'd32) issue_entry2 = search_entry2 + head + 5'd1 - 6'd32;
	//else issue_entry2 = search_entry2 + head + 5'd1;
//	issue_entry2 = search_entry2 + head;
	
	//operand func && target to ALU
	if (issue_valid2 && op_data[issue_entry2] == R_type) begin
		operand21_o = arg0_data[issue_entry2];
        operand22_o = arg1_data[issue_entry2];
		op_func2_o = {func_data[issue_entry2], op_data[issue_entry2]};
		target_bus2 = target_data[issue_entry2];
		end
	else if (issue_valid2 && (op_data[issue_entry2] == I_type2 || op_data[issue_entry2] == LOAD)) begin
		operand21_o = arg0_data[issue_entry2];
//	issue_entry2 = search_entry2 + head;
        operand22_o = imm_data[issue_entry2];
		op_func2_o = {func_data[issue_entry2], op_data[issue_entry2]};
		target_bus2 = target_data[issue_entry2];
		end
	else if (issue_valid2 && (op_data[issue_entry2] == STORE || op_data[issue_entry2] == BRANCH)) begin
			if(op_data[issue_entry2] == STORE) 
				if (op_data[issue_entry1] == LOAD || op_data[issue_entry1] == STORE) begin
					operand21_o = 32'd0;
            		operand22_o = 32'd0;
					op_func2_o = 17'd0;
					target_bus2 = 5'd0;
				end
				else begin 	
					operand21_o = arg0_data[issue_entry2];
                    operand22_o = imm_data[issue_entry2];
					op_func2_o = {func_data[issue_entry2], op_data[issue_entry2]};
					target_bus2 = 5'd0;
				end
			else//branch
				if (op_data[issue_entry1] == BRANCH || op_data[issue_entry1] == JUMP) begin  // assume U-type == Jump??
					operand21_o = 32'd0;
            	    operand22_o = 32'd0;
					op_func2_o = 17'd0;
					target_bus2 = 5'd0;
				end
				else begin
					operand21_o = arg0_data[issue_entry2];
                    operand22_o = arg1_data[issue_entry2];
					op_func2_o = {func_data[issue_entry2], op_data[issue_entry2]};
					target_bus2 = 5'd0;
				end
				end
	else if (issue_valid2 && op_data[issue_entry2] == JUMP) //jump
			if(op_data[issue_entry1] == BRANCH || op_data[issue_entry1] == JUMP) begin
				operand21_o = 32'd0;
                operand22_o = 32'd0;
				op_func2_o = 17'd0;
				target_bus2 = 5'd0;// bug????
			end
			else begin
				operand21_o = PC_data2;
                operand22_o = 32'd1;
				op_func2_o = {func_data[issue_entry2], op_data[issue_entry2]};
				target_bus2 = target_data[issue_entry2];// 5'd0;//reg0???
			end
	else begin 	//JR???
				operand21_o = 32'd0; 
                operand22_o = 32'd0;
				op_func2_o = 17'd0;
				target_bus2 = 5'd0;//broadcast R0 bug???????????????
		end
end

// Branch & Jump to PC-ALU
always_comb begin		
	if (issue_valid1 && op_data[issue_entry1] == BRANCH) begin
		pc_alu_operand1 = PC_data1;//change!!!!!!
        pc_alu_operand2 = imm_data[issue_entry1];
		jump_en_o = '0;
		if(result1_i) begin//?
			branch_en_o = '1; //???????????
			branch_PC_o = pc_alu_result;
			//jump_en_o = '0; //when branch, use jump_PC to pass branch current PC, in case multiple branches in ROB
			jump_PC_o = PC_data1;
			end
		else begin
			branch_en_o = '0;
		    branch_PC_o = 32'd0;
			jump_PC_o = 32'd0;
			end
		end
	else if (issue_valid1 && op_data[issue_entry1] == JUMP) begin// assume U_type = JUMP???
			pc_alu_operand1 = PC_data1;
            pc_alu_operand2 = imm_data[issue_entry1];
			jump_en_o = '1;
			jump_PC_o = pc_alu_result;
			branch_en_o = '0;
			branch_PC_o = PC_data1;
		end
	else begin
			//deps on the second
			//pc_alu_operand1 = 32'd0;
            //pc_alu_operand2 = 32'd0;	
		end

	if (issue_valid2 && op_data[issue_entry2] == BRANCH) begin
		if(op_data[issue_entry1] != BRANCH && op_data[issue_entry1] != JUMP) begin
			pc_alu_operand1 = PC_data2;
			pc_alu_operand2 = imm_data[issue_entry2];
			jump_en_o = '0;
			if(result2_i) begin
				branch_en_o = '1; 
				branch_PC_o = pc_alu_result;
				jump_PC_o = PC_data2;//current PC same as before
			end
			else begin
				branch_en_o = '0;
				branch_PC_o = 32'd0;
				jump_PC_o = 32'd0;
			end
		end
		else begin
			 //branch_en_o = '0;
			 //branch_PC_o = 32'd0;
			 //jump_en_o = '0;
			 //jump_PC_o = 32'd0;
		end
		end
	else if (issue_valid2 && op_data[issue_entry2] == JUMP) begin// assume U_type = JUMP???
			if(op_data[issue_entry1] != BRANCH && op_data[issue_entry1] != JUMP) begin
				pc_alu_operand1 = PC_data2;
				pc_alu_operand2 = imm_data[issue_entry2];
				jump_en_o = '1;
				jump_PC_o = pc_alu_result;
				branch_en_o = '0;
				branch_PC_o = PC_data2;
				end
			else begin
				//jump_en_o = '0;
				//jump_PC_o = 32'd0;
				//branch_en_o = '0;
				//branch_PC_o = 32'd0;
				//pc_alu_operand1 = 32'd0;
				//pc_alu_operand2 = 32'd0;
			end
		 end
	else if ((!issue_valid2 || (issue_valid2 && op_data[issue_entry2] != BRANCH && op_data[issue_entry2] != JUMP)) &&
			(op_data[issue_entry1] != BRANCH && op_data[issue_entry1] != JUMP)) ////?????????//
		begin
			pc_alu_operand1 = 32'd0;
            pc_alu_operand2 = 32'd0;	
			branch_en_o = '0;			
			jump_en_o = '0;
			branch_PC_o = 32'd0;
			jump_PC_o = 32'd0;
		end
		
	else;
	 
end//always


//Issue to LSQ
always_comb begin
	//1st instruction
	if(issue_valid1 && op_data[issue_entry1] == STORE)
		store_data_o = arg1_data[issue_entry1];
	else store_data_o = 32'd0;//deps on the second
	
	if(issue_valid1 && (op_data[issue_entry1] == STORE || op_data[issue_entry1] == LOAD)) begin
		addr_entry_o = entry[issue_entry1];
		addr_valid_o = '1;
	end
	else begin
		//deps on the second
		//addr_entry_o = 5'd0;
		//addr_valid_o = '0;
	end
	//second instruction
	if (issue_valid2 && op_data[issue_entry2] == LOAD) begin
		if(issue_valid2 && op_data[issue_entry1] != LOAD && op_data[issue_entry1] != STORE) begin
			addr_entry_o = entry[issue_entry2];
			addr_valid_o = '1;
			store_data_o = 32'd0; 
		end
		else begin
			//addr_entry_o = 5'd0;
			//addr_valid_o = '0;
		end
	end
	else if (issue_valid2 && op_data[issue_entry2] == STORE) begin
		if(op_data[issue_entry1] != LOAD && op_data[issue_entry1] != STORE) begin
			addr_entry_o = entry[issue_entry2];
			addr_valid_o = '1;
			store_data_o = arg1_data[issue_entry2];
		end
		else begin
			//addr_entry_o = 5'd0;
			//addr_valid_o = '0;
			//store_data_o = 32'd0;
		end
	end
	else if ((!issue_valid2 || (issue_valid2 && op_data[issue_entry2] != STORE && op_data[issue_entry2] != LOAD)) && 
			(!issue_valid1 || (issue_valid1 && op_data[issue_entry1] != LOAD && op_data[issue_entry1] != STORE))) 
		begin
			addr_entry_o = 5'd0;
			addr_valid_o = '0;
			store_data_o = 32'd0;
		end
	else;
end	
	 
//*************************************************ROB Broadcast****************************************************	 
    //seq:result_busN
	//result_busN = alu_resultN_i;
	
//search for broadcast right after exe
always_comb begin
for(int iter = 0 ; iter < 32 ; iter++) begin//broadcast 30 at most
	logic [4:0] i;
	//if(iter + head + '1 > 5'd31) i = iter + head + '1 - 6'd32;
	i = iter + head;

	//if(i == tail) break;

 
	//2nd instruction broadcast after exe
	if (target_bus1_ff == src0_data[i] && v0_data[i] == '0 && op_data_ff[issue_entry1_ff] != LOAD) //bug:when tar = 0, src =0 (for type without src0 src1 v0 v1 also = 0) 
		bcast_issue11[i] = '1;//address absolute
	else
		bcast_issue11[i] = '0;
	
	if (target_bus1_ff == src1_data[i] && v1_data[i] == '0 && op_data_ff[issue_entry1_ff] != LOAD) 
	   bcast_issue12[i] = '1;
	else
		bcast_issue12[i] = '0;
		
	//2nd instruction broadcast after exe	
	if (target_bus2_ff == src0_data[i] && v0_data[i] == '0 && op_data_ff[issue_entry2_ff] != LOAD) //bug:when tar = 0, src =0 (for type without src0 src1 v0 v1 also = 0) 
		bcast_issue21[i] = '1;//address absolute
	else
		bcast_issue21[i] = '0;
	
	if (target_bus2_ff == src1_data[i] && v1_data[i] == '0 && op_data_ff[issue_entry2_ff] != LOAD) 
       	bcast_issue22[i] = '1;
	else
		bcast_issue22[i] = '0;
	end//for
end//always	

//search for broadcast just before commit deallocate
always_comb begin	//??
for(int iter = 0 ; iter < 31 ; iter++) begin//broadcast 30 at most
	logic [4:0] i;
	//if(iter + head + '1 > 5'd31) i = iter + head + '1 - 6'd32;
	i = iter + head + 1;
     
	//if(i == tail)break;

	//??????
	if (WB_en1_o && (d_r1_valid && d_r1_data == '1) && WB_target1_o == src0_data[i] &&  v0_data[i] == '0)
		bcast_commit11[i] = '1;
	else
		bcast_commit11[i] = '0;
		
	if (WB_en1_o && (d_r1_valid && d_r1_data == '1) && WB_target1_o == src1_data[i] &&  v1_data[i] == '0)
		bcast_commit12[i] = '1;
	else
		bcast_commit12[i] = '0;	
		
	if (WB_en2_o && (d_r2_valid && d_r2_data == '1) && WB_target2_o == src0_data[i] &&  v0_data[i] == '0)
		bcast_commit21[i] = '1;
	else
		bcast_commit21[i] = '0;

	if (WB_en2_o && (d_r2_valid && d_r2_data == '1) && WB_target2_o == src1_data[i] &&  v1_data[i] == '0)
		bcast_commit22[i] = '1;
	else
		bcast_commit22[i] = '0;	
end //for
end//always


//v0&v1 arg0&arg1 4w 1r for 2 broadcasts

generate
for (genvar j = 0 ; j < 32 ; j++ ) begin
 ff_2r_6w #(.DATA_WIDTH(1)) ff_v0
   (
	.clk, .rst,
	.write1_en_i(bcast_issue11[j]), .write2_en_i(bcast_issue21[j]),.write3_en_i(bcast_commit11[j]), .write4_en_i(bcast_commit21[j]), 
	.write5_en_i(read11_ready_i  && index_tail[j]), .write6_en_i(read21_ready_i  && index_tail_2[j]),//enqueue v0
	.read1_en_i('1), .read2_en_i('1), 
    .data1_i('1), .data2_i('1), .data3_i('1), .data4_i('1), 
	.data5_i(read11_valid_bit_i), .data6_i(read21_valid_bit_i),
	.data1_o(v0_data[j]), .data2_o()
   );
   
 ff_2r_6w #(.DATA_WIDTH(1)) ff_v1
   (
	.clk, .rst,
	.write1_en_i(bcast_issue12[j]), .write2_en_i(bcast_issue22[j]),.write3_en_i(bcast_commit12[j]), .write4_en_i(bcast_commit22[j]), 
	.write5_en_i(read12_ready_i  && index_tail[j]), .write6_en_i(read22_ready_i  && index_tail_2[j]),//enquue v1
	.read1_en_i('1), .read2_en_i('1), 
    .data1_i('1), .data2_i('1), .data3_i('1), .data4_i('1), 
	.data5_i(read12_valid_bit_i), .data6_i(read22_valid_bit_i),
	.data1_o(v1_data[j]), .data2_o()
   );
/*
ff_argN(.write_en1(bcast_issue1[j]), .write_data1(result_bus1_ff), 
	.write_en2(bcast_issue2[j]), .write_data2(result_bus2), 
	.write_en3(bcast_commit1[j]), .write_data3(WB_data1_o), 
.write_en4(bcast_commit1[j]), .write_data4(WB_data2_o), 
);
*/
 ff_2r_6w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_arg0
   (
	.clk, .rst,
	.write1_en_i(bcast_issue11[j]), .write2_en_i(bcast_issue21[j]),.write3_en_i(bcast_commit11[j]), .write4_en_i(bcast_commit21[j]), 
	.write5_en_i(read11_ready_i && index_tail[j]), .write6_en_i(read21_ready_i && index_tail_2[j]),//enqueue argument0
	.read1_en_i('1), .read2_en_i('1), 
    .data1_i(result_bus1_ff), .data2_i(result_bus2_ff), .data3_i(WB_data1_o), .data4_i(WB_data2_o), .data5_i(read11_data_i), .data6_i(read21_data_i),
	.data1_o(arg0_data[j]), .data2_o()
   ); 
   
 ff_2r_6w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_arg1
   (
	.clk, .rst,
	.write1_en_i(bcast_issue12[j]), .write2_en_i(bcast_issue22[j]),.write3_en_i(bcast_commit12[j]), .write4_en_i(bcast_commit22[j]), 
	.write5_en_i(read12_ready_i && index_tail[j]), .write6_en_i(read22_ready_i && index_tail_2[j]),//enqueue argument1
	.read1_en_i('1), .read2_en_i('1), 
    .data1_i(result_bus1_ff), .data2_i(result_bus2_ff), .data3_i(WB_data1_o), .data4_i(WB_data2_o), .data5_i(read12_data_i), .data6_i(read22_data_i),
	.data1_o(arg1_data[j]), .data2_o()
   ); 
end
endgenerate

//*************************************************ROB Commit****************************************************
// commit 2 instructions at most
assign d_r1_en = '1;
assign d_r2_en = '1;


always_comb begin
	//commit from head
	WB_target1_o = target_data[head];
	if(d_r1_valid && d_r1_data == '1)//D[head]
	  if(op_data[head] == LOAD)
		case(func_data[head][2:0])
		001: begin //load data direcly to Regfile//LH
				WB_data1_o = {{16{load_data_i[15]}}, load_data_i[15:0] };//??
			end
		000: begin//LB
				WB_data1_o = {{24{load_data_i[7]}}, load_data_i[7:0] };//??
			end
		010: begin//LW
				WB_data1_o = load_data_i;
			end
		100: begin//LBU
				WB_data1_o = {{24{'0}}, load_data_i[7:0] };//??
			end
		101: begin//LHU
				WB_data1_o = {{16{'0}}, load_data_i[15:0] };//??
			end
		default: begin
				WB_data1_o = load_data_i;
				 end
		endcase
	  else begin
			WB_data1_o = result_r1_data;  
		   end
end

assign WB_en1_o = (d_r1_valid && d_r1_data && op_data[head] != STORE && op_data[head] != BRANCH && op_data[head] != JR) ? '1:'0;
 
always_comb begin
	if (head + 5'd1 > 5'd31)
		head_2 = head + 5'd1 - 6'd32; //the index right after "head"
	else
		head_2 = head + 5'd1;
end

//logic [REGNAME_WIDTH-1:0] result_r1_addr, result_r2_addr;

always_comb begin
	WB_target2_o = target_data[head_2];
	if((d_r1_valid && d_r1_data == '1) && (d_r2_valid && d_r2_data == '1)) begin
		if(op_data[head] != LOAD && op_data[head_2] == LOAD)
			case(func_data[head_2][2:0])//??
			001: begin //load data direcly to Regfile //LH
				WB_data2_o = {{16{load_data_i[15]}}, load_data_i[15:0] };//??
			end
			000: begin//LB
				WB_data2_o = {{24{load_data_i[7]}}, load_data_i[7:0] };//??
			end
			010: begin//LW
				WB_data2_o = load_data_i;
			end
			100: begin//LBU
				WB_data2_o = {{24{'0}}, load_data_i[7:0] };//??
			end
			101: begin//LHU
				WB_data2_o = {{16{'0}}, load_data_i[15:0] };//??
			end
			default: begin
				WB_data2_o = load_data_i;
			end
			endcase
	//	end
		else begin
			WB_data2_o = result_r2_data;
		end
	end
end//always

//WB_en2_o
always_comb begin
	if((d_r1_valid && d_r1_data == '1) && (d_r2_valid && d_r2_data == '1))
		if (op_data[head] == LOAD && op_data[head_2] == LOAD ||
			(op_data[head_2] == STORE || op_data[head_2] == BRANCH) || op_data[head_2] == JR)
			WB_en2_o = '0;
       else
			WB_en2_o = '1;
     else
	 	WB_en2_o = '0;
end//always

//commit count	
always_comb begin		
	if (d_r1_valid == '0 || d_r1_data == '0)//!D[head]
		comcnt = 2'd0;
	else if ( (d_r1_valid == '1 && d_r1_data == '1) && 
			(d_r2_valid == '0 || d_r2_data == '0)) //D[head] && !D[head]
			comcnt = 2'd1;
	else begin //both done
		if (op_data[head] == LOAD && op_data[head_2] == LOAD) 
			comcnt = 2'd1;//both loads
		else if (op_data[head] == STORE && op_data[head_2] == STORE) 
			comcnt = 2'd1;//both stores
		else
			comcnt = 2'd2;
	end	
end//always


//commit with LSQ
//commit load
always_comb begin
	//load_commit_entry
	if((d_r1_valid && d_r1_data == '1) && op_data[head] == LOAD)
		load_commit_entry_o = entry[head];//error in pseudo
	else
		load_commit_entry_o = entry[head_2];
	
	//load_commit_valid
	if ( ((d_r1_valid && d_r1_data == '1) && op_data[head] == LOAD)  || 
     ((d_r1_valid && d_r1_data == '1) && op_data[head] != LOAD && ((d_r2_valid && d_r2_data == '1) && op_data[head_2] == LOAD)) )
		load_commit_valid_o = '1;
	else
		load_commit_valid_o = '0;	
end//always

//commit stire
always_comb begin
	//store index	
	if ((d_r1_valid && d_r1_data == '1) && op_data[head] == STORE)
		store_commit_entry_o = entry[head];
	else
		store_commit_entry_o = entry[head_2];
	//store valid
	if ( ((d_r1_valid && d_r1_data == '1) && op_data[head] == STORE) || 
     ((d_r1_valid && d_r1_data == '1) && op_data[head] != STORE && (d_r2_valid && d_r2_data == '1) && op_data[head_2] == STORE) )
		store_commit_valid_o = '1;
	else
		store_commit_valid_o = '0;
end//always
 
endmodule
