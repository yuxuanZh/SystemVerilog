`include "src/sub_units/ff_3r_3w.sv"
module ram_3r_3w #(parameter OPRAND_WIDTH = 8,
				 parameter ARRAY_ENTRY = 32,
				 parameter REGNAME_WIDTH = 5)
  (input clk, rst,
   input write1_en_i, write2_en_i, write3_en_i,
   input [REGNAME_WIDTH-1:0] write1_addr_i, write2_addr_i, write3_addr_i,
   input [OPRAND_WIDTH-1:0] write1_data_i, write2_data_i, write3_data_i,
   input read1_en_i, read2_en_i, read3_en_i,
   input [REGNAME_WIDTH-1:0] read1_addr_i, read2_addr_i, read3_addr_i,
   output logic [OPRAND_WIDTH-1:0] read1_data_o, read2_data_o, read3_data_o
 //  output logic read1_ready_o, read2_ready_o, read3_ready_o
  );
  
//write/read data & valid enable 
logic [ARRAY_ENTRY-1:0] write1_en;//write "valid"
logic [ARRAY_ENTRY-1:0] write2_en;
logic [ARRAY_ENTRY-1:0] write3_en;

logic [ARRAY_ENTRY-1:0] read1_en;//read "valid" 
logic [ARRAY_ENTRY-1:0] read2_en;
logic [ARRAY_ENTRY-1:0] read3_en;

//read "valid"
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read1_valid_bit;
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read2_valid_bit;
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read3_valid_bit;

logic read1_ready_o, read2_ready_o, read3_ready_o;
//read and write index after decode
logic [ARRAY_ENTRY-1:0] index_valid1_write, index_valid2_write, index_valid3_write;
logic [ARRAY_ENTRY-1:0] index_read1, index_read2, index_read3;

generate
for (genvar i=0;i<ARRAY_ENTRY;i++) begin

	assign write1_en[i] = write1_en_i && index_valid1_write[i];
	assign write2_en[i] = write2_en_i && index_valid2_write[i];
	assign write3_en[i] = write3_en_i && index_valid3_write[i];
	
	assign read1_en[i] = read1_en_i && index_read1[i];
	assign read2_en[i] = read2_en_i && index_read2[i];
	assign read3_en[i] = read3_en_i && index_read3[i];
	
	//3 read 3 write
	ff_3r_3w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_valid 
								 (.clk,
								  .rst,
								  
								  .write1_en_i(write1_en[i]),
								  .write2_en_i(write2_en[i]),
								  .write3_en_i(write3_en[i]),
								  
								  .read1_en_i(read1_en[i]),
								  .read2_en_i(read2_en[i]),
								  .read3_en_i(read3_en[i]),
								  
								  //write "0" has priority than "1"
								  .data1_i(write1_data_i),
								  .data2_i(write2_data_i),
								  .data3_i(write3_data_i),
								  
								  .data1_o(read1_valid_bit[i]),
								  .data2_o(read2_valid_bit[i]),
								  .data3_o(read3_valid_bit[i])
								  );
end
endgenerate

//write address Decoder
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_valid1
				    (.index_i(write1_addr_i),
			         .index_depth_o(index_valid1_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_valid2
				    (.index_i(write2_addr_i),
			         .index_depth_o(index_valid2_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_data1
				    (.index_i(write3_addr_i),
			         .index_depth_o(index_valid3_write)
					 );
					 
//read address Decoder
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read1
				    (.index_i(read1_addr_i),
			         .index_depth_o(index_read1)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read2
				    (.index_i(read2_addr_i),
			         .index_depth_o(index_read2)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read3
				    (.index_i(read3_addr_i),
			         .index_depth_o(index_read3)
					 );
	  
//read valid MUX
mux  #(.WID(8))mux_read1_valid
						(.index_i(read1_addr_i),
						 .data_i(read1_valid_bit),
						 .read_en_i(read1_en_i),
                         .data_o(read1_data_o),
						 .read_ready_o(read1_ready_o)
						 );
						 
mux  #(.WID(8))mux_read2_valid
						(.index_i(read2_addr_i),
						 .data_i(read2_valid_bit),
						 .read_en_i(read2_en_i),
                         .data_o(read2_data_o),
						 .read_ready_o(read2_ready_o)
						 );

mux  #(.WID(8))mux_read3_valid
						(.index_i(read3_addr_i),
						 .data_i(read3_valid_bit),
						 .read_en_i(read3_en_i),
                         .data_o(read3_data_o),
						 .read_ready_o(read3_ready_o)
						 );

						 
endmodule
