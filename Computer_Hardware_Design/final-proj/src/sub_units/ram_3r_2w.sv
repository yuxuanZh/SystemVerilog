`include "src/sub_units/ff_3r_2w.sv"
module ram_3r_2w #(parameter OPRAND_WIDTH = 32,
				 parameter ARRAY_ENTRY = 32,
				 parameter REGNAME_WIDTH = 5)
  (input clk, rst,
   input [OPRAND_WIDTH-1:0] write1_data_i, write2_data_i,
   input [REGNAME_WIDTH-1:0] write1_addr_i, write2_addr_i,
   input [REGNAME_WIDTH-1:0] read1_addr_i, read2_addr_i, read3_addr_i,
   input write1_en_i, write2_en_i,
   input read1_en_i, read2_en_i, read3_en_i,
   output logic [OPRAND_WIDTH-1:0] read1_data_o, read2_data_o, read3_data_o,
   output logic read1_ready_o, read2_ready_o, read3_ready_o
  );
  
//write/read data & valid enable 
logic [ARRAY_ENTRY-1:0] write1_en;//write data
logic [ARRAY_ENTRY-1:0] write2_en;
logic [ARRAY_ENTRY-1:0] read1_en;//read "valid" & data
logic [ARRAY_ENTRY-1:0] read2_en;
logic [ARRAY_ENTRY-1:0] read3_en;

//read and write index after decode
logic [ARRAY_ENTRY-1:0] index_data1_write, index_data2_write;
logic [ARRAY_ENTRY-1:0] index_read1, index_read2, index_read3;

//read data
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read1_data;
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read2_data;
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read3_data;

generate
for (genvar i=0;i<ARRAY_ENTRY;i++) begin

	assign write1_en[i] = write1_en_i && index_data1_write[i];
	assign write2_en[i] = write2_en_i && index_data2_write[i];
	
	assign read1_en[i] = read1_en_i && index_read1[i];
	assign read2_en[i] = read2_en_i && index_read2[i];
	assign read3_en[i] = read3_en_i && index_read3[i];
	//3 read 2 write							  
	ff_3r_2w #(.DATA_WIDTH(OPRAND_WIDTH)) ff_3r_2w_1 
										  (.clk,
										   .rst,
										   
										   .write1_en_i(write1_en[i]),
										   .write2_en_i(write2_en[i]),
										   
										   .read1_en_i(read1_en[i]),
										   .read2_en_i(read2_en[i]),						
										   .read3_en_i(read3_en[i]),
										   
										   .data1_i(write1_data_i),
										   .data2_i(write2_data_i),
										   
										   .data1_o(read1_data[i]),
										   .data2_o(read2_data[i]),
										   .data3_o(read3_data[i])
										   );
end
endgenerate

//write address Decoder					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_data1
				    (.index_i(write1_addr_i),
			         .index_depth_o(index_data1_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_data2
				    (.index_i(write2_addr_i),
			         .index_depth_o(index_data2_write)
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
										
	  
//read data MUX
mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read1_data
						(.index_i(read1_addr_i),
						 .data_i(read1_data),
						 .read_en_i(read1_en_i),
                         .data_o(read1_data_o),
						 .read_ready_o(read1_ready_o)
						 );
						 
mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read2_data
						(.index_i(read2_addr_i),
						 .data_i(read2_data),
						 .read_en_i(read2_en_i),
                         .data_o(read2_data_o),
						 .read_ready_o(read2_ready_o)
						 );
						 
mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read3_data
						(.index_i(read3_addr_i),
						 .data_i(read3_data),
						 .read_en_i(read3_en_i),
                         .data_o(read3_data_o),
						 .read_ready_o(read3_ready_o)
						 );
endmodule
