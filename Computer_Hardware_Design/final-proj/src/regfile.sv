`include "src/sub_units/ram_4r_2w.sv"
`include "src/sub_units/ram_4r_4w.sv"

module regfile #(parameter OPRAND_WIDTH = 16,
				 parameter ARRAY_ENTRY = 32,
				 parameter REGNAME_WIDTH = 5)
  (input clk, rst,
   ifc_dec_rf.rf dec,
   ifc_rob_rf.rf rob
  );

logic read11_ready_data, read12_ready_data, read21_ready_data, read22_ready_data,
	  read11_ready_valid, read12_ready_valid, read21_ready_valid, read22_ready_valid;

logic [OPRAND_WIDTH-1:0] read11_data, read12_data, read21_data, read22_data;
logic read11_valid_bit, read12_valid_bit, read21_valid_bit, read22_valid_bit;

ram_4r_2w #(.OPRAND_WIDTH(OPRAND_WIDTH),
				   .ARRAY_ENTRY(ARRAY_ENTRY),
				   .REGNAME_WIDTH(REGNAME_WIDTH)) data_ram
  (
	.clk, 
	.rst,
	.write1_data_i(rob.WB_data1), 
	.write2_data_i(rob.WB_data2),
	.write1_addr_i(rob.WB_target1), 
	.write2_addr_i(rob.WB_target2),
	.read11_addr_i(dec.read11_addr), 
	.read12_addr_i(dec.read12_addr), 
	.read21_addr_i(dec.read21_addr), 
	.read22_addr_i(dec.read22_addr),
	.write1_en_i(rob.WB_en1), 
	.write2_en_i(rob.WB_en2),
	.read11_en_i(dec.read11_en), 
	.read12_en_i(dec.read12_en), 
	.read21_en_i(dec.read21_en), 
	.read22_en_i(dec.read22_en),
	.read11_data_o(read11_data), 
	.read12_data_o(read12_data), 
	.read21_data_o(read21_data), 
	.read22_data_o(read22_data),
	.read11_ready_o(read11_ready_data), 
	.read12_ready_o(read12_ready_data), 
	.read21_ready_o(read21_ready_data), 
	.read22_ready_o(read22_ready_data)
  );

ram_4r_4w #(.OPRAND_WIDTH('1),
				   .ARRAY_ENTRY(ARRAY_ENTRY),
				   .REGNAME_WIDTH(REGNAME_WIDTH)) valid_ram
  (
	.clk, 
	.rst,
	.write11_data_i('0), //enqueue
	.write12_data_i('0),
	.write21_data_i('1), //WB
	.write22_data_i('1),
	.write11_addr_i(dec.write1_addr), 
	.write12_addr_i(dec.write2_addr),
	.write21_addr_i(rob.WB_target1), 
	.write22_addr_i(rob.WB_target2),
	.read11_addr_i(dec.read11_addr), 
	.read12_addr_i(dec.read12_addr), 
	.read21_addr_i(dec.read21_addr), 
	.read22_addr_i(dec.read22_addr),
	.write11_en_i(dec.write1_en), 
	.write12_en_i(dec.write2_en),
	.write21_en_i(rob.WB_en1), 
	.write22_en_i(rob.WB_en2),
	.read11_en_i(dec.read11_en), 
	.read12_en_i(dec.read12_en), 
	.read21_en_i(dec.read21_en), 
	.read22_en_i(dec.read22_en),
	.read11_data_o(read11_valid_bit), 
	.read12_data_o(read12_valid_bit), 
	.read21_data_o(read21_valid_bit), 
	.read22_data_o(read22_valid_bit),
	.read11_ready_o(read11_ready_valid), 
	.read12_ready_o(read12_ready_valid), 
	.read21_ready_o(read21_ready_valid), 
	.read22_ready_o(read22_ready_valid)
  );
	
	 
	 
assign  rob.read11_ready = read11_ready_data && read11_ready_valid;
assign  rob.read12_ready = read12_ready_data && read12_ready_valid;
assign  rob.read21_ready = read21_ready_data && read21_ready_valid;
assign  rob.read22_ready = read22_ready_data && read22_ready_valid;

	//corner_case: data dependency among two in-flight instructions at enqueue stage
	always_comb begin 
	
		if(dec.write1_addr == dec.read21_addr && dec.write1_en) begin 
			rob.read21_valid_bit = '0;
			rob.read21_data = read21_data;
			//$display("dep btw two enqueued instructions R1");
			end
		else if(rob.WB_target1 == dec.read21_addr && rob.WB_en1) begin
			  rob.read21_valid_bit = '1;
			  rob.read21_data = rob.WB_data1;
			end
		else if(rob.WB_target2 == dec.read21_addr && rob.WB_en2) begin
			  rob.read21_valid_bit = '1;
			  rob.read21_data = rob.WB_data2;
			end
		else begin
			  rob.read21_valid_bit = read21_valid_bit;
			  rob.read21_data = read21_data;
			end
			
		if(dec.write1_addr == dec.read22_addr && dec.write1_en) begin
			rob.read22_valid_bit = '0;
			rob.read22_data = read22_data;
			//$display("dep btw two enqueued instructions R2");
			end
		else if(rob.WB_target1 == dec.read22_addr && rob.WB_en1) begin
			rob.read22_valid_bit = '1;
			rob.read22_data = rob.WB_data1;
			end
		else if(rob.WB_target2 == dec.read22_addr && rob.WB_en2) begin
			rob.read22_valid_bit = '1;
			rob.read22_data = rob.WB_data2;
			end
		else begin
			rob.read22_valid_bit = read22_valid_bit;
			rob.read22_data = read22_data;
			end
	end
					
	//corner_case: write and read data/â€œvalidâ€ consistency
	always_comb begin 
	
	if(rob.WB_target1 == dec.read11_addr && rob.WB_en1) begin 
			rob.read11_valid_bit = '1;
			rob.read11_data = rob.WB_data1;
		end
	else if(rob.WB_target2 == dec.read11_addr && rob.WB_en2) begin
			rob.read11_valid_bit = '1;
			rob.read11_data = rob.WB_data2;
		end
	else begin
			rob.read11_valid_bit = read11_valid_bit;
			rob.read11_data = read11_data;
		 end
		
	if(rob.WB_target1 == dec.read12_addr && rob.WB_en1) begin 
			rob.read12_valid_bit = '1;
			rob.read12_data = rob.WB_data1;
		end	
	else if(rob.WB_target2 == dec.read12_addr && rob.WB_en2) begin
			rob.read12_valid_bit = '1;
			rob.read12_data = rob.WB_data2;
		end
	else begin
			rob.read12_valid_bit = read12_valid_bit;
			rob.read12_data = read12_data;
		 end
	/*	
	if(rob.WB_target1 == dec.read21_addr) begin 
			rob.read21_valid_bit = '1;
			rob.read21_data = rob.WB_data1;
		end	
	else begin
			rob.read21_valid_bit = read21_valid_bit;
			rob.read21_data = read21_data;
		 end
	*/
	/*
	if(rob.WB_target1 == dec.read22_addr) begin 
			rob.read22_valid_bit = '1;
			rob.read22_data = rob.WB_data1;
		end	
	else begin
			rob.read22_valid_bit = read22_valid_bit;
			rob.read22_data = read22_data;
		 end	
	*/	
		/*
	if(rob.WB_target2 == dec.read11_addr) begin 
			rob.read11_valid_bit = '1;
			rob.read11_data = rob.WB_data2;
		end	
	else begin
			rob.read11_valid_bit = read11_valid_bit;
			rob.read11_data = read11_data;
		 end
		
	if(rob.WB_target2 == dec.read12_addr) begin 
			rob.read12_valid_bit = '1;
			rob.read12_data = rob.WB_data2;
		end
	else begin
			rob.read12_valid_bit = read12_valid_bit;
			rob.read12_data = read12_data;
		 end
		 */
/*		
	if(rob.WB_target2 == dec.read21_addr) begin 
			rob.read21_valid_bit = '1;
			rob.read21_data = rob.WB_data2;
		end
	else begin
			rob.read21_valid_bit = read21_valid_bit;
			rob.read21_data = read21_data;
		 end
		
	if(rob.WB_target2 == dec.read22_addr) begin 
			rob.read22_valid_bit = '1;
			rob.read22_data = rob.WB_data2;
		end
	else begin
			rob.read22_valid_bit = read22_valid_bit;
			rob.read22_data = read22_data;
		 end
	*/
	end			
endmodule
