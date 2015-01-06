//modified by Yuxuan @ 12/12
module head_tail_control #(parameter INDEX_WIDTH = 5)
	(
	input clk, rst,
	input [INDEX_WIDTH-1:0] head_i, tail_i,
	input [1:0] comcnt_i,
	input [INDEX_WIDTH-1:0] tail_branch_jump_i, tail_lsq_flush_i,
	input ins1_valid_i, ins2_valid_i,
	output logic [INDEX_WIDTH-1:0] head_o, tail_o,
	output logic full_o,
	output logic [INDEX_WIDTH-1:0] flush_index_o//index in ROB which causes flush
	);
	
logic [INDEX_WIDTH:0] full_cnt;
logic [INDEX_WIDTH-1:0] tail_temp1, tail_temp2, tail_temp3, tail_temp4;

//assign tail_temp1 = tail_branch_jump_i;
//assign tail_temp2 =	tail_lsq_flush_i;
assign tail_temp1 = '0;
assign tail_temp2 =	'0;
assign full_o = (full_cnt >= 6'd29) ? '1 : '0;
/*
//distance between LSQ flush/branch/jump to tail_i
always_comb begin
	if (tail_i < tail_temp1) 
		tail_temp3 = tail_i + 6'd32 - tail_temp1;
	else 
		tail_temp3 = tail_i - tail_temp1;//if no flush distance is 0
		
	if (tail_i < tail_temp2) 
		tail_temp4 = tail_i + 6'd32 - tail_temp2;
	else 
		tail_temp4 = tail_i - tail_temp2;
end
*/
assign tail_temp3 = tail_i - tail_temp1;
assign tail_temp4 = tail_i - tail_temp2;

//flush PC
always_comb begin
	if(tail_temp3 < tail_temp4)
		flush_index_o = tail_temp2;//??
	else flush_index_o = tail_temp1;
end

//full_cnt
always_ff @(posedge clk) begin
	if(rst) full_cnt <= 6'd0;
	else if(ins1_valid_i && ins2_valid_i)
		full_cnt <= full_cnt + 6'd2 -  comcnt_i;
	else if((ins1_valid_i && !ins2_valid_i) || (!ins1_valid_i && ins2_valid_i))
		full_cnt <= full_cnt + 6'd1 -  comcnt_i;
	else 
		full_cnt <= full_cnt  -  comcnt_i;
end

//head
always_ff @(posedge clk) begin
	if(rst) head_o <= 5'd0;
	else begin
	if (head_i + comcnt_i > 5'd31)
		head_o <= head_i + comcnt_i - 6'd32;
	else
		head_o <= head_i + comcnt_i;
	end
end//always

//tail
always_ff @(posedge clk) begin
	if(rst) tail_o <= 6'd0;
	else begin
	if(tail_temp3 < tail_temp4)
		tail_o <= tail_temp2;//??
	else if (tail_temp3 > tail_temp4)
		tail_o <= tail_temp1;
	else if(ins1_valid_i && ins2_valid_i)
		if(tail_i + 5'd2 > 5'd31) tail_o <= tail_i + 5'd2 - 6'd32;
		else tail_o <= tail_i + 6'd2;
	else if((ins1_valid_i && !ins2_valid_i) || (!ins1_valid_i && ins2_valid_i))
		if(tail_i + 5'd1 > 5'd31) tail_o <= tail_i + 5'd1 - 6'd32;
		else tail_o <= tail_i + 5'd1;
	else;
	end
end

endmodule
