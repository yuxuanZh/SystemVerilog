`include "src/sub_units/ff_regfile.sv"
`include "src/sub_units/mux.sv"
module ram_4r_2w #(parameter OPRAND_WIDTH = 32,
				 parameter ARRAY_ENTRY = 32,
				 parameter REGNAME_WIDTH = 5)
  (input clk, rst,
   input [OPRAND_WIDTH-1:0] write1_data_i, write2_data_i,
   input [REGNAME_WIDTH-1:0] write1_addr_i, write2_addr_i,
   input [REGNAME_WIDTH-1:0] read11_addr_i, read12_addr_i, read21_addr_i, read22_addr_i,
   input write1_en_i, write2_en_i,
   input read11_en_i, read12_en_i, read21_en_i, read22_en_i,
   output logic [OPRAND_WIDTH-1:0] read11_data_o, read12_data_o, read21_data_o, read22_data_o,
   output logic read11_ready_o, read12_ready_o, read21_ready_o, read22_ready_o
  );
  
//write/read data & valid enable 
logic [ARRAY_ENTRY-1:0] write1_en;//write data
logic [ARRAY_ENTRY-1:0] write2_en;
logic [ARRAY_ENTRY-1:0] read11_en;//read "valid" & data
logic [ARRAY_ENTRY-1:0] read12_en;
logic [ARRAY_ENTRY-1:0] read21_en;
logic [ARRAY_ENTRY-1:0] read22_en;
//read and write index after decode
logic [ARRAY_ENTRY-1:0] index_data1_write, index_data2_write;
logic [ARRAY_ENTRY-1:0] index_read11, index_read12, index_read21, index_read22;

//read data
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read11_data;
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read12_data;
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read21_data;
logic [ARRAY_ENTRY-1:0] [OPRAND_WIDTH-1:0] read22_data;

generate
for (genvar i=0;i<ARRAY_ENTRY;i++) begin

	assign write1_en[i] = write1_en_i && index_data1_write[i];
	assign write2_en[i] = write2_en_i && index_data2_write[i];
	
	assign read11_en[i] = read11_en_i && index_read11[i];
	assign read12_en[i] = read12_en_i && index_read12[i];
	assign read21_en[i] = read21_en_i && index_read21[i];
	assign read22_en[i] = read22_en_i && index_read22[i];
	
	//4 read 2 write							  
	ff_regfile #(.DATA_WIDTH(OPRAND_WIDTH)) ff_data 
										  (.clk,
										   .rst,
										   
										   .write1_en_i(write1_en[i]),
										   .write2_en_i(write2_en[i]),
										   
										   .read11_en_i(read11_en[i]),
										   .read12_en_i(read12_en[i]),
										   .read21_en_i(read21_en[i]),
										   .read22_en_i(read22_en[i]),
										   
										   .data1_i(write1_data_i),
										   .data2_i(write2_data_i),
										   
										   .data11_o(read11_data[i]),
										   .data12_o(read12_data[i]),
										   .data21_o(read21_data[i]),
										   .data22_o(read22_data[i])
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
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read11
				    (.index_i(read11_addr_i),
			         .index_depth_o(index_read11)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read12
				    (.index_i(read12_addr_i),
			         .index_depth_o(index_read12)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read21
				    (.index_i(read21_addr_i),
			         .index_depth_o(index_read21)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_read22
				    (.index_i(read22_addr_i),
			         .index_depth_o(index_read22)
					 );
	  
//read data MUX
mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read11_data
						(.index_i(read11_addr_i),
						 .data_i(read11_data),
						 .read_en_i(read11_en_i),
                         .data_o(read11_data_o),
						 .read_ready_o(read11_ready_o)
						 );
						 
mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read12_data
						(.index_i(read12_addr_i),
						 .data_i(read12_data),
						 .read_en_i(read12_en_i),
                         .data_o(read12_data_o),
						 .read_ready_o(read12_ready_o)
						 );

mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read21_data
						(.index_i(read21_addr_i),
						 .data_i(read21_data),
						 .read_en_i(read21_en_i),
                         .data_o(read21_data_o),
						 .read_ready_o(read21_ready_o)
						 );

mux #(.WIDTH(REGNAME_WIDTH),.WID(OPRAND_WIDTH)) mux_read22_data
						(.index_i(read22_addr_i),
						 .data_i(read22_data),
						 .read_en_i(read22_en_i),
                         .data_o(read22_data_o),
						 .read_ready_o(read22_ready_o)
						 );		

						 
endmodule
