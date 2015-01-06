//modified by SenLin @ 12/14

`include "src/sub_units/ff_1r_3w.sv"
`include "src/sub_units/ram_3r_3w.sv"

module lsq #(parameter OPRAND_WIDTH = 32, parameter INDEX_WIDTH = 5,
             parameter LSQ_DEPTH = 1 << INDEX_WIDTH, parameter SUBDATA_WIDTH = 8)
  (input clk, rst,
   ifc_rob_lsq.lsq rob,
   //ifc_rob_alu.lsq alu,
   
   //connect ALU
   input [OPRAND_WIDTH-1:0] result_addr_i,
   
   //connect memory
   input mem_load_valid_i,
   input [OPRAND_WIDTH-1:0] mem_load_value_i,
   output logic mem_store_en_o, mem_load_en_o,
   output [1:0] mem_store_type_o, mem_load_type_o,//3types
   output logic [OPRAND_WIDTH-1:0] mem_store_addr_o, mem_load_addr_o,
   output logic [OPRAND_WIDTH-1:0] mem_store_value_o
   );
//type field 3 bits
//LB LH includes opcode LBU, LHU, which will be extended in ROB
parameter LSQ_WIDTH = 32;
parameter LB = 3'b000, LH = 3'b001, LW = 3'b010, SB = 3'b100, SH = 3'b101, SW = 3'b110, LOAD = 3'b0xx, STORE = 3'b1xx;
parameter Word2Word = 5'b00000, RWord2Half = 5'b00001, LWord2Half = 5'b00010, FWord2Byte = 5'b00011, SWord2Byte = 5'b00100,
		  TWord2Byte = 	5'b00101, FrWord2Byte = 5'b00110, Half2RWord = 5'b00111, Half2LWord = 5'b01000, Half2Half = 5'b01001,
		  LHalf2Byte = 5'b01010, RHalf2Byte = 5'b01011, Byte2FWord = 5'b01100, Byte2SWord = 5'b01101, Byte2TWord = 5'b01110, 
		  Byte2FrWord = 5'b01111, Byte2RHalf = 5'b10000, Byte2LHalf = 5'b10001, Byte2Byte = 5'b10010, None = 5'b10011;
	
//IO
logic ls_valid1_i, ls_valid2_i, addr_valid_i, load_commit_valid_i, store_commit_valid_i;
logic [2:0] ls_type1_i, ls_type2_i;
logic [INDEX_WIDTH-1:0] ls_entry1_o, ls_entry2_o, addr_entry_i, load_commit_entry_i, store_commit_entry_i, flush_entry_o;
logic [OPRAND_WIDTH-1:0] store_data_i, load_data_o, load_data_tmp;

//ff
logic [INDEX_WIDTH-1:0] addr_entry_i_ff;
logic [2:0] type_cam_r1_data_ff;

//enqueue
logic [INDEX_WIDTH-1:0] head, head_2, tail, tail_2;
//logic type_cam_w1_en, type_cam_w2_en;
//logic [INDEX_WIDTH-1:0] type_cam_w1_index, type_cam_w2_index;
//logic [2:0] type_cam_w1_data, type_cam_w2_data;

//issue & execution
//logic addr_cam_w1_en; 
//logic [INDEX_WIDTH-1:0] addr_cam_w1_index, av_cam_w1_index;
//logic [OPRAND_WIDTH-1:0] addr_cam_w1_data;
//logic av_cam_w1_en;
//logic av_cam_w1_data;
//one result_addr_i channel
//logic type_cam_r1_en, type_cam_r1_valid, type_cam_r1_ready;
//logic [INDEX_WIDTH-1:0] type_cam_r1_index;
logic [2:0] type_cam_r1_data;

//write data port 1 for STORE
logic data0_cam_w1_en, data1_cam_w1_en, data2_cam_w1_en, data3_cam_w1_en;
logic [SUBDATA_WIDTH-1:0] data0_cam_w1_data, data1_cam_w1_data, data2_cam_w1_data, data3_cam_w1_data;
logic [INDEX_WIDTH-1:0] data0_cam_w1_index, data1_cam_w1_index, data2_cam_w1_index, data3_cam_w1_index;
//write data port 2 for LOAD
logic data3_cam_w2_en, data2_cam_w2_en, data1_cam_w2_en, data0_cam_w2_en;
logic [INDEX_WIDTH-1:0] data3_cam_w2_index, data2_cam_w2_index, data1_cam_w2_index, data0_cam_w2_index;
logic [SUBDATA_WIDTH-1:0] data3_cam_w2_data, data2_cam_w2_data, data1_cam_w2_data, data0_cam_w2_data;
//write data port 3 for LOAD when bypass
logic data3_cam_w3_en, data2_cam_w3_en, data1_cam_w3_en, data0_cam_w3_en;
logic [INDEX_WIDTH-1:0] data3_cam_w3_index, data2_cam_w3_index, data1_cam_w3_index, data0_cam_w3_index;
logic [SUBDATA_WIDTH-1:0] data3_cam_w3_data, data2_cam_w3_data, data1_cam_w3_data, data0_cam_w3_data;
// Dv write port 1 for STORE
//logic dv3_cam_w1_en, dv2_cam_w1_en, dv1_cam_w1_en, dv0_cam_w1_en;
//logic [INDEX_WIDTH-1:0] dv3_cam_w1_index, dv2_cam_w1_index, dv1_cam_w1_index, dv0_cam_w1_index;
//logic dv3_cam_w1_data, dv2_cam_w1_data, dv1_cam_w1_data, dv0_cam_w1_data;
// Dv write port 2 for Load
//logic dv3_cam_w2_en, dv2_cam_w2_en, dv1_cam_w2_en, dv0_cam_w2_en;
//logic [INDEX_WIDTH-1:0] dv3_cam_w2_index, dv2_cam_w2_index, dv1_cam_w2_index, dv0_cam_w2_index;
//logic dv3_cam_w2_data, dv2_cam_w2_data, dv1_cam_w2_data, dv0_cam_w2_data;

//commit
//data read port 1 for LOAD
logic data3_cam_r1_en, data2_cam_r1_en, data1_cam_r1_en, data0_cam_r1_en;
logic [INDEX_WIDTH-1:0] data3_cam_r1_index, data2_cam_r1_index, data1_cam_r1_index, data0_cam_r1_index;
logic [SUBDATA_WIDTH-1:0] data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r1_data;
//reset av port 2 when commit LOAD
//logic av_cam_w2_en;
//logic [INDEX_WIDTH-1:0] av_cam_w2_index;
//logic av_cam_w2_data;
//data read port 2 for STORE
logic data3_cam_r2_en, data2_cam_r2_en, data1_cam_r2_en, data0_cam_r2_en;
logic [INDEX_WIDTH-1:0] data3_cam_r2_index, data2_cam_r2_index, data1_cam_r2_index, data0_cam_r2_index;
logic [SUBDATA_WIDTH-1:0] data3_cam_r2_data, data2_cam_r2_data, data1_cam_r2_data, data0_cam_r2_data;
//data read port 3 for STORE bypass
logic data3_cam_r3_en, data2_cam_r3_en, data1_cam_r3_en, data0_cam_r3_en;
logic [INDEX_WIDTH-1:0] data3_cam_r3_index, data2_cam_r3_index, data1_cam_r3_index, data0_cam_r3_index;
logic [SUBDATA_WIDTH-1:0] data3_cam_r3_data, data2_cam_r3_data, data1_cam_r3_data, data0_cam_r3_data;
//reset av port 3 when commit STORE
//logic av_cam_w3_en;
//logic [INDEX_WIDTH-1:0] av_cam_w3_index;
//logic av_cam_w3_data;
//commit store read address and send to memory
//logic addr_cam_r1_en;
//logic [INDEX_WIDTH-1:0] addr_cam_r1_index;
//logic [OPRAND_WIDTH-1:0] addr_cam_r1_data;
//port 2 for send store type to mem
//logic type_cam_r2_en, type_cam_r2_ready;
//logic [INDEX_WIDTH-1:0] type_cam_r2_index;
//logic [2:0] type_cam_r2_data;

//Bypass
logic [LSQ_DEPTH-1:0] search_bypass_index1, search_flush_index2;
logic [INDEX_WIDTH-1:0] search_bypass_entry1, search_flush_entry2, bypass_entry1, flush_entry2;
logic search_bypass_valid1, search_flush_valid2;
logic [4:0] search_type;

logic [LSQ_WIDTH-1:0] addr_index, index_tail, index_tail_2;
logic [LSQ_WIDTH-1:0] [OPRAND_WIDTH-1:0]addr_cam_data;
logic [LSQ_WIDTH-1:0] av_cam_data;
logic [LSQ_WIDTH-1:0] [2:0] type_cam_data;

//rename interface
assign ls_valid1_i = rob.ls_valid1;
assign ls_valid2_i = rob.ls_valid2;
assign ls_type1_i = rob.ls_type1;
assign ls_type2_i = rob.ls_type2;
assign rob.ls_entry1 = ls_entry1_o;
assign rob.ls_entry2 = ls_entry2_o;
assign addr_entry_i = rob.addr_entry;
assign addr_valid_i = rob.addr_valid;
assign store_data_i = rob.store_data;
assign load_commit_entry_i = rob.load_commit_entry;
assign load_commit_valid_i = rob.load_commit_valid;
assign rob.load_data = load_data_o;
//assign rob.load_data_valid = load_data_valid_o;
assign store_commit_entry_i = rob.store_commit_entry;
assign store_commit_valid_i = rob.store_commit_valid;




//*************************************************LSQ Enqueue****************************************************
//enqueue 3-bit type
/*
assign type_cam_w1_en = ls_valid1_i;
assign type_cam_w2_en = ls_valid2_i;
assign type_cam_w1_index = tail;
assign type_cam_w2_index = tail_2;
assign type_cam_w1_data = ls_type1_i;
assign type_cam_w2_data = ls_type2_i;
*/
// tail and tail_2
always_ff @(posedge clk) begin
	if(rst)
		tail <= 0;
	else if(rob.flush_valid)
		tail <= rob.flush_entry;
	else if(rob.ls_valid1 && rob.ls_valid2) 
		tail <= tail+5'd2;
	else if(rob.ls_valid1 || rob.ls_valid2)
		tail <= tail+5'd1;
	else;	
end
		
assign tail_2 = tail+5'd1;

//return entry index
assign ls_entry1_o = ls_valid1_i ? tail : 5'b0;
assign ls_entry2_o = ls_valid2_i ? tail_2 : 5'b0;

//reset av = 0
//assign av_cam_w1_en = ls_valid1_i;
//assign av_cam_w1_index = tail;
//assign av_cam_w1_data = '0;

//assign av_cam_w2_en = ls_valid2_i;
//assign av_cam_w2_index = tail_2;
//assign av_cam_w2_data = '0;
//*************************************************LSQ Execution****************************************************
//allocate address after execution 
//assign addr_cam_w1_en = addr_valid_i; 
//assign addr_cam_w1_index = addr_entry_i; 
//assign addr_cam_w1_data = result_addr_i;

//av bit
//assign av_cam_w3_en = addr_valid_i;
//assign av_cam_w3_index = addr_entry_i;
//assign av_cam_w3_data = '1; //reset 0 after commit extra port????????when enqueue

// delay addr_entry and type_cam_r1_data for one cycle 
always_ff @(posedge clk) begin
	if(rst)
		addr_entry_i_ff <= 0;
	else
		addr_entry_i_ff <= rob.addr_entry;
end

assign type_cam_r1_data = type_cam_data[addr_entry_i];

always_ff @(posedge clk) begin
	if(rst)
		type_cam_r1_data_ff <= 0;
	else
		type_cam_r1_data_ff <= type_cam_r1_data;
end

//store data enable together with addr in
//loads not need data, determined by Dv
assign data3_cam_w1_en = addr_valid_i;
assign data2_cam_w1_en = addr_valid_i;
assign data1_cam_w1_en = addr_valid_i;
assign data0_cam_w1_en = addr_valid_i;
assign data3_cam_w1_index = addr_entry_i;//??????????????????? yuan lai wang le jia
assign data2_cam_w1_index = addr_entry_i;//??????????????????????wrong!!!!!!!!!!! same as load
assign data1_cam_w1_index = addr_entry_i;
assign data0_cam_w1_index = addr_entry_i;

assign data3_cam_w1_data = store_data_i[31:24];
assign data2_cam_w1_data = store_data_i[23:16];
assign data1_cam_w1_data = store_data_i[15:8];
assign data0_cam_w1_data = store_data_i[7:0];

//type read data & valid are used when write dv
//assign type_cam_r1_en = addr_valid_i;
//assign type_cam_r1_index = addr_entry_i;

//data valid bit write dep on opcode type
//assign dv3_cam_w1_en = addr_valid_i;
//assign dv2_cam_w1_en = addr_valid_i;
//assign dv1_cam_w1_en = addr_valid_i;
//assign dv0_cam_w1_en = addr_valid_i;
//assign dv3_cam_w1_index = addr_entry_i;
//assign dv2_cam_w1_index = addr_entry_i;
//assign dv1_cam_w1_index = addr_entry_i;
//assign dv0_cam_w1_index = addr_entry_i;
//?????????????????????????????????????????????????????????????????????????????????????????????????
//assign dv3_cam_w1_data = (addr_valid_i && (type_cam_data[addr_entry_i] == SW)) ? '1 : '0;
//assign dv2_cam_w1_data = (addr_valid_i && (type_cam_data[addr_entry_i] == SW)) ? '1 : '0;
//assign dv1_cam_w1_data = (addr_valid_i && (type_cam_data[addr_entry_i] == SW || type_cam_r1_data == SH)) ? '1 : '0;
//assign dv0_cam_w1_data = (addr_valid_i && (type_cam_data[addr_entry_i] == STORE)) ? '1 : '0;


//load data as soon as LOAD gets address
//assign mem_load_en_o = (addr_valid_i && type_cam_data[addr_entry_i] == LOAD) ? '1 : '0;
assign mem_load_en_o = (addr_valid_i && type_cam_data[addr_entry_i][2] == 1'b0) ? '1 : '0;
assign mem_load_type_o = addr_valid_i ? type_cam_data[addr_entry_i][1:0] : 2'b0;
assign mem_load_addr_o = result_addr_i;//give the addr to mem directly not waiting visible in LSQ
                                       //the first bit of needed data
											
//write port 2 for load
always_comb begin
	if (mem_load_valid_i) begin
		if (search_bypass_valid1 && (bypass_entry1 == addr_entry_i_ff)) begin
			data3_cam_w2_en = 0;
			data2_cam_w2_en = 0;
			data1_cam_w2_en = 0;
			data0_cam_w2_en = 0;
		end else begin
			data3_cam_w2_en = 1;
			data2_cam_w2_en = 1;
			data1_cam_w2_en = 1;
			data0_cam_w2_en = 1;
		end
	end else begin
		data3_cam_w2_en = 0;
		data2_cam_w2_en = 0;
		data1_cam_w2_en = 0;
		data0_cam_w2_en = 0;
	end
end

//assign data3_cam_w2_en = mem_load_valid_i && (search_bypass_valid1 ? (bypass_entry1 != addr_entry_i_ff : 1));
//assign data2_cam_w2_en = mem_load_valid_i && (search_bypass_valid1 ? (bypass_entry1 != addr_entry_i_ff : 1));
//assign data1_cam_w2_en = mem_load_valid_i && (search_bypass_valid1 ? (bypass_entry1 != addr_entry_i_ff : 1));
//assign data0_cam_w2_en = mem_load_valid_i && (search_bypass_valid1 ? (bypass_entry1 != addr_entry_i_ff : 1));
assign data3_cam_w2_index = addr_entry_i_ff;//delay one cycle synchronous to read data
assign data2_cam_w2_index = addr_entry_i_ff;
assign data1_cam_w2_index = addr_entry_i_ff;
assign data0_cam_w2_index = addr_entry_i_ff;
//This is different from LOAD data commit in ROB?????????????????????????????????????????????????????///
//result address in is the address of [31]
assign data3_cam_w2_data = mem_load_value_i[31:24];
assign data2_cam_w2_data = mem_load_value_i[23:16];
assign data1_cam_w2_data = mem_load_value_i[15:8];
assign data0_cam_w2_data = mem_load_value_i[7:0];

//PS: need to check the bypass data corner case???
// 
//load access memory use an address and the next cycle write data back to load
//At the same time, a previous store commit with the same address, seeing load need to bypass.
//Bypass has higher priority than data from memory
//

//write port 2 for load
//assign dv3_cam_w2_en = mem_load_valid_i && (addr_valid_i ? (addr_entry_i != addr_entry_i_ff : 1));
//assign dv2_cam_w2_en = mem_load_valid_i && (addr_valid_i ? (addr_entry_i != addr_entry_i_ff : 1));
//assign dv1_cam_w2_en = mem_load_valid_i && (addr_valid_i ? (addr_entry_i != addr_entry_i_ff : 1));
//assign dv0_cam_w2_en = mem_load_valid_i && (addr_valid_i ? (addr_entry_i != addr_entry_i_ff : 1));
//assign dv3_cam_w2_index = addr_entry_i_ff;//two dv data no contention, write-time & address are different, 
//assign dv2_cam_w2_index = addr_entry_i_ff;
//assign dv1_cam_w2_index = addr_entry_i_ff;
//assign dv0_cam_w2_index = addr_entry_i_ff;
//
//assign dv3_cam_w2_data = (type_cam_r1_ready && (type_cam_r1_data_ff == LW)) ? '1 : '0;
//assign dv2_cam_w2_data = (type_cam_r1_ready && (type_cam_r1_data_ff == LW)) ? '1 : '0;
//assign dv1_cam_w2_data = (type_cam_r1_ready && (type_cam_r1_data_ff == LW || type_cam_r1_data_ff == LH)) ? '1 : '0;
//assign dv0_cam_w2_data = (type_cam_r1_ready && (type_cam_r1_data_ff == LOAD)) ? '1 : '0;

//*************************************************LSQ Commit************************************************************
//commit one load or one store (one load and store at the same time ?????s) at most one cycle, which is controlled by ROB
//commit LOAD
assign data3_cam_r1_en = load_commit_valid_i;
assign data2_cam_r1_en = load_commit_valid_i;
assign data1_cam_r1_en = load_commit_valid_i;
assign data0_cam_r1_en = load_commit_valid_i;
assign data3_cam_r1_index = load_commit_entry_i;
assign data2_cam_r1_index = load_commit_entry_i;
assign data1_cam_r1_index = load_commit_entry_i;
assign data0_cam_r1_index = load_commit_entry_i;

// need to judge
always_comb begin
if (rob.load_commit_valid && rob.store_commit_valid && (rob.load_commit_entry == bypass_entry1))
	load_data_o = load_data_tmp;
else
	load_data_o =  {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r1_data};
end
//???????????????????????????????????????????????????????????????????????????????????????????????????????????????????
//invalidate the address valid bit when commit load & store, not care address data


//commit STORE
//send memory store type 2 bits
//assign type_cam_r2_en = store_commit_valid_i;
//assign type_cam_r2_index = store_commit_entry_i;
//read data to be stored
assign data3_cam_r2_en = store_commit_valid_i;
assign data2_cam_r2_en = store_commit_valid_i;
assign data1_cam_r2_en = store_commit_valid_i;
assign data0_cam_r2_en = store_commit_valid_i;
assign data3_cam_r2_index = store_commit_entry_i;
assign data2_cam_r2_index = store_commit_entry_i;
assign data1_cam_r2_index = store_commit_entry_i;
assign data0_cam_r2_index = store_commit_entry_i;
//read address of the data to be stored
//assign addr_cam_r1_en = store_commit_valid_i;
//assign addr_cam_r1_index = store_commit_entry_i;
assign mem_store_addr_o =  addr_cam_data[store_commit_entry_i];
//transfer data and 2-bit type memory
assign mem_store_en_o = store_commit_valid_i;
assign mem_store_type_o = type_cam_data[addr_entry_i][1:0];
assign mem_store_value_o = {data3_cam_r2_data, data2_cam_r2_data, data1_cam_r2_data, data0_cam_r2_data};

//reset AV when enqueue

//*************************************************LSQ Bypass****************************************************
//av_cam_data[i] 1 addr_cam_data[i]32 type_cam_data[i] 3 visible


decoder #(.WIDTH(5)) decoder_addr_entry_i//exe
				    (.index_i(addr_entry_i),
			         .index_depth_o(addr_index)
					 );
					 
decoder #(.WIDTH(5)) decoder_tail
				    (.index_i(tail),
			         .index_depth_o(index_tail)
					 );
					 
decoder #(.WIDTH(5)) decoder_tail_2
				    (.index_i(tail_2),
			         .index_depth_o(index_tail_2)
					 );
					 
					 


generate
for (genvar i = 0 ; i < LSQ_DEPTH ; i++ ) begin

 ff_1r_1w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_addr_cam_data   
   (
	.clk, .rst,
	.write_en_i(addr_valid_i && addr_index[i]), //write when exe
	.read_en_i('1),  
    .data_i(result_addr_i),  
	.data_o(addr_cam_data[i])//one read port no contention for search and for store mem
   ); 
   
  ff_1r_3w #(.DATA_WIDTH(1)) ff_av_cam_data  
   (
	.clk, .rst,
	.write1_en_i(ls_valid1_i && index_tail[i]),.write2_en_i(ls_valid2_i && index_tail_2[i]),
	.write3_en_i(addr_valid_i && addr_index[i]),
	.read1_en_i('1), 
    .data1_i('0), .data2_i('0), .data3_i('1), 
	.data1_o(av_cam_data[i])
   ); 
   

 ff_2r_2w #(.DATA_WIDTH(3)) ff_type_cam_data 
   (
	.clk, .rst,
	.write1_en_i(ls_valid1_i && index_tail[i]),.write2_en_i(ls_valid2_i && index_tail_2[i]),
	.read1_en_i('1), .read2_en_i(), 
    .data1_i(ls_type1_i), .data2_i(ls_type2_i), 
	.data1_o(type_cam_data[i]), .data2_o() //3 read no contention??
   ); 
   
end
endgenerate



always_comb begin
	for (int iter = 0 ; iter < 32 ; iter++) begin
		int i;
		if(iter + store_commit_entry_i + 5'd1 > 5'd31)  i = iter + store_commit_entry_i + 5'd1 - 6'd32;
		else i = iter + store_commit_entry_i + 5'd1;
		
		//end of bypass
		//if(i == tail) break;
	
		//search_bypass_index1
		if(type_cam_data[store_commit_entry_i] == SW) begin
			if (av_cam_data[i] && type_cam_data[i] == LW) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i])
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LH) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[i] == addr_cam_data[store_commit_entry_i] + 32'd2)
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;				
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LB) begin
				if ((addr_cam_data[i] == addr_cam_data[store_commit_entry_i])|| 
					(addr_cam_data[i] == addr_cam_data[store_commit_entry_i] + 32'd1) ||
				    (addr_cam_data[i] == addr_cam_data[store_commit_entry_i] + 32'd2) || 
					(addr_cam_data[i] == addr_cam_data[store_commit_entry_i] + 32'd3))
					search_bypass_index1[iter] = 1'b1;				
				else
					search_bypass_index1[iter] = 1'b0;				
			end	
			
			else search_bypass_index1[iter] = 1'b0;
		end
		
		else if(type_cam_data[store_commit_entry_i] == SH) begin
			if (av_cam_data[i] && type_cam_data[i] == LW) begin
				if ((addr_cam_data[i] == addr_cam_data[store_commit_entry_i]) || 
					(addr_cam_data[i] + 32'd2 == addr_cam_data[store_commit_entry_i]))
					search_bypass_index1[iter] = 1'b1;			
				else
					search_bypass_index1[iter] = 1'b0;				
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LH) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i])
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LB) begin
				if ((addr_cam_data[i] == addr_cam_data[store_commit_entry_i]) || 
					(addr_cam_data[i] == addr_cam_data[store_commit_entry_i] + 32'd1))
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;				
			end			
		end
		
		else if(type_cam_data[store_commit_entry_i] == SB) begin
			if (av_cam_data[i] && type_cam_data[i] == LW) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[i] + 32'd1 == addr_cam_data[store_commit_entry_i] ||
				    addr_cam_data[i] + 32'd2 == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[i] + 32'd3 == addr_cam_data[store_commit_entry_i] )
					search_bypass_index1[iter] = 1'b1;					
				else
					search_bypass_index1[iter] = 1'b0;				
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LH) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[i] + 32'd1 == addr_cam_data[store_commit_entry_i])
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LB) begin
				if (addr_cam_data[i] == addr_cam_data[store_commit_entry_i])
					search_bypass_index1[iter] = 1'b1;
				else
					search_bypass_index1[iter] = 1'b0;				
			end				
		end
		
		else search_bypass_index1[iter] = 1'b0;
		
	end		
end

pencoder #(.WIDTH(6)) priority_encoder_bypass1 (.search_valid_i(search_bypass_index1),.search_index_o(search_bypass_entry1));

//always_comb begin
//	//search_valid_o
//	if(|search_bypass_index1) search_bypass_valid1 = '1;
//	else search_bypass_valid1 = '0;
//
//	//bypass_entry1 (bound)
//	if(store_commit_entry_i + search_bypass_entry1 + 1 > 5'd31) bypass_entry1 = store_commit_entry_i + search_bypass_entry1 - 5'd31;
//	else bypass_entry1 = store_commit_entry_i + search_bypass_entry1 + 1;
//end

assign head = store_commit_entry_i;
logic [5:0]length1;
assign length1 = (tail >= head) ? tail - head : tail + 6'd32 - head;
//assign search_bypass_valid1 = '0;

always_comb begin
	if(search_bypass_entry1 + 1'd1 < length1 && search_bypass_entry1[5] == 0)
		search_bypass_valid1 = 1;
	else
		search_bypass_valid1 = 0;
end

assign bypass_entry1 = store_commit_entry_i + search_bypass_entry1 + 5'd1;

always_comb begin
    if(search_bypass_valid1) begin  
		//search_type
		if(type_cam_data[store_commit_entry_i] == SW) begin
			if (type_cam_data[bypass_entry1] == LW) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Word2Word;
				else
					search_type = None;
			end
		
			else if (type_cam_data[bypass_entry1] == LH) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = LWord2Half;//???
				else if(addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i] + 32'd2)
					search_type = RWord2Half;//??				
				else			
					search_type = None;
			end
			
			else if (type_cam_data[bypass_entry1] == LB) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = FWord2Byte;
				else if(addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i] + 32'd1)
					search_type = SWord2Byte;		
				else if(addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i] + 32'd2)
					search_type = TWord2Byte;	
				else if(addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i] + 32'd3)
					search_type = FrWord2Byte;						
				else			
					search_type = None;
			end	
			
			else search_type = None;
		end
		
		else if(type_cam_data[store_commit_entry_i] == SH) begin
			if (type_cam_data[bypass_entry1] == LW) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Half2LWord;
				else if(addr_cam_data[bypass_entry1] + 32'd2 == addr_cam_data[store_commit_entry_i])
					search_type = Half2RWord;				
				else
					search_type = None;			
			end
		
			else if (type_cam_data[bypass_entry1] == LH) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Half2Half;
				else
					search_type = None;
			end
			
			else if (type_cam_data[bypass_entry1] == LB) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = LHalf2Byte;
				else if(addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i] + 32'd1)
					search_type = RHalf2Byte;	
				else
					search_type = None;		
			end			
		end
		
		else if(type_cam_data[store_commit_entry_i] == SB) begin
			if (type_cam_data[bypass_entry1] == LW) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Byte2FWord;
				else if(addr_cam_data[bypass_entry1] + 32'd1 == addr_cam_data[store_commit_entry_i])
					search_type = Byte2SWord;		
				else if(addr_cam_data[bypass_entry1] + 32'd2 == addr_cam_data[store_commit_entry_i])
					search_type = Byte2TWord;		
				else if(addr_cam_data[bypass_entry1] + 32'd3 == addr_cam_data[store_commit_entry_i])
					search_type = Byte2FrWord;						
				else
					search_type = None;		
			end
		
			else if (type_cam_data[bypass_entry1] == LH) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Byte2LHalf;
				else if (addr_cam_data[bypass_entry1] + 32'd1 == addr_cam_data[store_commit_entry_i])
					search_type = Byte2RHalf;
				else
					search_type = None;
			end
			
			else if (type_cam_data[bypass_entry1] == LB) begin
				if (addr_cam_data[bypass_entry1] == addr_cam_data[store_commit_entry_i])
					search_type = Byte2Byte;
				else
					search_type = None;		
			end				
		end
		
		else search_type = None;	
	end//if
	
	case(search_type)		
			Word2Word: begin //N = 0~3
				data3_cam_r3_en = 1;
				data3_cam_r3_index = store_commit_entry_i;
				data3_cam_w3_en = 1;
				data3_cam_w3_index = bypass_entry1;				
				data3_cam_w3_data = data3_cam_r3_data;
				data2_cam_r3_en = 1;
				data2_cam_r3_index = store_commit_entry_i;
				data2_cam_w3_en = 1;
				data2_cam_w3_index = bypass_entry1;				
				data2_cam_w3_data = data3_cam_r2_data;
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data3_cam_r1_data;
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data3_cam_r3_data;
                load_data_tmp  = {data3_cam_r3_data, data2_cam_r3_data, data1_cam_r3_data, data0_cam_r3_data};
			end
			RWord2Half: begin //N = 0~1
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data1_cam_r3_data;
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r3_data};
			end			
			LWord2Half: begin 
				data2_cam_r3_en = 1;
				data2_cam_r3_index = store_commit_entry_i;
				data3_cam_r3_en = 1;
				data3_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data2_cam_r3_data;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data3_cam_r3_data;
				data0_cam_r3_en = 0;
				data1_cam_r3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r3_data};
			end						
			FWord2Byte: begin 
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end	
			SWord2Byte: begin 
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data1_cam_r3_data;
				data0_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end			
			TWord2Byte: begin 
				data2_cam_r3_en = 1;
				data2_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data2_cam_r3_data;
				data0_cam_r3_en = 0;
				data1_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end		
			FrWord2Byte: begin 
				data3_cam_r3_en = 1;
				data3_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data3_cam_r3_data;
				data0_cam_r3_en = 0;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end		
			Half2RWord: begin //N = 0~1
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data1_cam_r3_data;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r3_data};
			end			
			Half2LWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data2_cam_w3_en = 1;
				data2_cam_w3_index = bypass_entry1;				
				data2_cam_w3_data = data0_cam_r3_data;
				data3_cam_w3_en = 1;
				data3_cam_w3_index = bypass_entry1;				
				data3_cam_w3_data = data1_cam_r3_data;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data0_cam_w3_en = 0;
				data1_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r3_data, data2_cam_r3_data, data1_cam_r1_data, data0_cam_r1_data};
			end	
			Half2Half: begin //N = 0~1
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data1_cam_r3_data;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r3_data};
			end			
			LHalf2Byte: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end			
			RHalf2Byte: begin
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data1_cam_r3_data;
				data0_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end		
			Byte2FWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end		
			Byte2SWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data0_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r1_data};
			end		
			Byte2TWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data2_cam_w3_en = 1;
				data2_cam_w3_index = bypass_entry1;				
				data2_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data0_cam_w3_en = 0;
				data1_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r3_data, data1_cam_r1_data, data0_cam_r1_data};
			end		
			Byte2FrWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data3_cam_w3_en = 1;
				data3_cam_w3_index = bypass_entry1;				
				data3_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data0_cam_w3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r3_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r1_data};
			end				
			Byte2RHalf: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end	 
			Byte2LHalf: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = bypass_entry1;				
				data1_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data0_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r3_data, data0_cam_r1_data};
			end	 			
			Byte2Byte: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = bypass_entry1;				
				data0_cam_w3_data = data0_cam_r3_data;
				data1_cam_r3_en = 0;
				data2_cam_r3_en = 0;
				data3_cam_r3_en = 0;
				data1_cam_w3_en = 0;
				data2_cam_w3_en = 0;
				data3_cam_w3_en = 0;
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r3_data};
			end	 	
			default: begin //N = 0~3
				data3_cam_r3_en = 0;
				data3_cam_r3_index = 5'b0;
				data3_cam_w3_en = 0;
				data3_cam_w3_index = 5'b0;				
				data3_cam_w3_data = 8'b0;		
				data2_cam_r3_en = 0;
				data2_cam_r3_index = 5'b0;
				data2_cam_w3_en = 0;
				data2_cam_w3_index = 5'b0;				
				data2_cam_w3_data = 8'b0;		
				data1_cam_r3_en = 0;
				data1_cam_r3_index = 5'b0;
				data1_cam_w3_en = 0;
				data1_cam_w3_index = 5'b0;				
				data1_cam_w3_data = 8'b0;		
				data0_cam_r3_en = 0;
				data0_cam_r3_index = 5'b0;
				data0_cam_w3_en = 0;
				data0_cam_w3_index = 5'b0;				
				data0_cam_w3_data = 8'b0;		
                load_data_tmp  = {data3_cam_r1_data, data2_cam_r1_data, data1_cam_r1_data, data0_cam_r1_data};
			end
	endcase
end//always


always_comb begin
	//find second load
	for (int iter2  = 0 ; iter2 < 32 ; iter2++) begin
		int j;
		if(iter2 + bypass_entry1 + 5'd1 > 5'd31)  j = iter2 + bypass_entry1 + 5'd1 - 6'd32;
		else j = iter2 + bypass_entry1 + 5'd1;
		
		//end of bypass
		//if(j == tail) break;

		//search_valid2
		if(type_cam_data[store_commit_entry_i] == SW) begin
			if (av_cam_data[j] && type_cam_data[j] == LW) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i])
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LH) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] == addr_cam_data[store_commit_entry_i] + 32'd2)
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;				
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LB) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] == addr_cam_data[store_commit_entry_i] + 32'd1 ||
				    addr_cam_data[j] == addr_cam_data[store_commit_entry_i] + 32'd2 || 
					addr_cam_data[j] == addr_cam_data[store_commit_entry_i] + 32'd3)
					search_flush_index2[iter2] = 1'b1;				
				else
					search_flush_index2[iter2] = 1'b0;				
			end	
			
			else search_flush_index2[iter2] = 1'b0;
		end
		
		else if(type_cam_data[store_commit_entry_i] == SH) begin
			if (av_cam_data[j] && type_cam_data[j] == LW) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] + 32'd2 == addr_cam_data[store_commit_entry_i])
					search_flush_index2[iter2] = 1'b1;			
				else
					search_flush_index2[iter2] = 1'b0;				
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LH) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i])
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LB) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] == addr_cam_data[store_commit_entry_i] + 32'd1)
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;				
			end			
		end
		
		else if(type_cam_data[store_commit_entry_i] == SB) begin
			if (av_cam_data[j] && type_cam_data[j] == LW) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] + 32'd1 == addr_cam_data[store_commit_entry_i] ||
				    addr_cam_data[j] + 32'd2 == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] + 32'd3 == addr_cam_data[store_commit_entry_i] )
					search_flush_index2[iter2] = 1'b1;					
				else
					search_flush_index2[iter2] = 1'b0;				
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LH) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i] || 
					addr_cam_data[j] + 32'd1 == addr_cam_data[store_commit_entry_i])
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LB) begin
				if (addr_cam_data[j] == addr_cam_data[store_commit_entry_i])
					search_flush_index2[iter2] = 1'b1;
				else
					search_flush_index2[iter2] = 1'b0;				
			end				
		end
		
		else search_flush_index2[iter2] = 1'b0;
		
	end		
end

pencoder #(.WIDTH(6)) priority_encoder_bypass2 (.search_valid_i(search_flush_index2),.search_index_o(search_flush_entry2));

//assign rob.flush_valid = (|search_flush_index2) ? 1'b1 : 0;
//assign rob.flush_valid = |search_flush_index2;
//assign rob.flush_valid = '0;

logic [5:0] length2;
assign length2 = (tail >= bypass_entry1 + 6'd1) ? tail - bypass_entry1 - 6'd1 : tail - bypass_entry1 +6'd31;

always_comb begin
	if(rob.flush_entry + 1'd1 < length2 && search_flush_entry2[5] == 0)
		rob.flush_valid = 1;
	else
		rob.flush_valid = 0;
end


assign rob.flush_entry = store_commit_entry_i + search_flush_entry2 + 5'd1;
//always_comb begin
//	//flush_valid_o
//	if(|search_flush_index2) search_flush_valid2 = 1;
//	else search_flush_valid2 = 0;
//	
//	//flush_index_o (bound)
//	if(store_commit_entry_i + search_bypass_entry1 > 5'd31) flush_entry2 = store_commit_entry_i + search_flush_entry2 - 5'd32;
//	else flush_entry2 = store_commit_entry_i + search_flush_entry2;	
//end

// w1 for store issue, w2 for load mem, w3 for bypass
// r1 for load commit, r2 for store commit, r3 for bypass
ram_3r_3w #(.OPRAND_WIDTH(8)) ram_data3 
(	.clk, .rst,
	.write1_en_i(data3_cam_w1_en),      .write2_en_i(data3_cam_w2_en),      .write3_en_i(data3_cam_w3_en),
	.write1_addr_i(data3_cam_w1_index), .write2_addr_i(data3_cam_w2_index), .write3_addr_i(data3_cam_w3_index),
	.write1_data_i(data3_cam_w1_data),  .write2_data_i(data3_cam_w2_data),  .write3_data_i(data3_cam_w3_data),
	.read1_en_i(data3_cam_r1_en),       .read2_en_i(data3_cam_r2_en),       .read3_en_i(data3_cam_r3_en),
	.read1_addr_i(data3_cam_r1_index),  .read2_addr_i(data3_cam_r2_index),  .read3_addr_i(data3_cam_r3_index),
	.read1_data_o(data3_cam_r1_data),   .read2_data_o(data3_cam_r2_data),   .read3_data_o(data3_cam_r3_data)
);


ram_3r_3w #(.OPRAND_WIDTH(8)) ram_data2 
(	.clk, .rst,
	.write1_en_i(data2_cam_w1_en),      .write2_en_i(data2_cam_w2_en),      .write3_en_i(data2_cam_w3_en),
	.write1_addr_i(data2_cam_w1_index), .write2_addr_i(data2_cam_w2_index), .write3_addr_i(data2_cam_w3_index),
	.write1_data_i(data2_cam_w1_data),  .write2_data_i(data2_cam_w2_data),  .write3_data_i(data2_cam_w3_data),
	.read1_en_i(data2_cam_r1_en),       .read2_en_i(data2_cam_r2_en),       .read3_en_i(data2_cam_r3_en),
	.read1_addr_i(data2_cam_r1_index),  .read2_addr_i(data2_cam_r2_index),  .read3_addr_i(data2_cam_r3_index),
	.read1_data_o(data2_cam_r1_data),   .read2_data_o(data2_cam_r2_data),   .read3_data_o(data2_cam_r3_data)
);

ram_3r_3w #(.OPRAND_WIDTH(8)) ram_data1 
(	.clk, .rst,
	.write1_en_i(data1_cam_w1_en),      .write2_en_i(data1_cam_w2_en),      .write3_en_i(data1_cam_w3_en),
	.write1_addr_i(data1_cam_w1_index), .write2_addr_i(data1_cam_w2_index), .write3_addr_i(data1_cam_w3_index),
	.write1_data_i(data1_cam_w1_data),  .write2_data_i(data1_cam_w2_data),  .write3_data_i(data1_cam_w3_data),
	.read1_en_i(data1_cam_r1_en),       .read2_en_i(data1_cam_r2_en),       .read3_en_i(data1_cam_r3_en),
	.read1_addr_i(data1_cam_r1_index),  .read2_addr_i(data1_cam_r2_index),  .read3_addr_i(data1_cam_r3_index),
	.read1_data_o(data1_cam_r1_data),   .read2_data_o(data1_cam_r2_data),   .read3_data_o(data1_cam_r3_data)
);

ram_3r_3w #(.OPRAND_WIDTH(8)) ram_data0
(	.clk, .rst,
	.write1_en_i(data0_cam_w1_en),      .write2_en_i(data0_cam_w2_en),      .write3_en_i(data0_cam_w3_en),
	.write1_addr_i(data0_cam_w1_index), .write2_addr_i(data0_cam_w2_index), .write3_addr_i(data0_cam_w3_index),
	.write1_data_i(data0_cam_w1_data),  .write2_data_i(data0_cam_w2_data),  .write3_data_i(data0_cam_w3_data),
	.read1_en_i(data0_cam_r1_en),       .read2_en_i(data0_cam_r2_en),       .read3_en_i(data0_cam_r3_en),
	.read1_addr_i(data0_cam_r1_index),  .read2_addr_i(data0_cam_r2_index),  .read3_addr_i(data0_cam_r3_index),
	.read1_data_o(data0_cam_r1_data),   .read2_data_o(data0_cam_r2_data),   .read3_data_o(data0_cam_r3_data)
);

endmodule


