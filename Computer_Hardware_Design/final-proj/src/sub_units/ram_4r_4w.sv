`include "src/sub_units/ff_valid.sv"
`include "src/sub_units/decoder.sv"
module ram_4r_4w #(parameter OPRAND_WIDTH = 16,
				 parameter ARRAY_ENTRY = 32,
				 parameter REGNAME_WIDTH = 5)
  (input clk, rst,
   input [OPRAND_WIDTH-1:0] write11_data_i, write12_data_i, write21_data_i, write22_data_i,
   input [REGNAME_WIDTH-1:0] write11_addr_i, write12_addr_i, write21_addr_i, write22_addr_i,
   input [REGNAME_WIDTH-1:0] read11_addr_i, read12_addr_i, read21_addr_i, read22_addr_i,
   input write11_en_i, write12_en_i, write21_en_i, write22_en_i,
   input read11_en_i, read12_en_i, read21_en_i, read22_en_i,
   output logic [OPRAND_WIDTH-1:0] read11_data_o, read12_data_o, read21_data_o, read22_data_o,
   output logic read11_ready_o, read12_ready_o, read21_ready_o, read22_ready_o
  );
  
//write/read data & valid enable 
logic [ARRAY_ENTRY-1:0] write1_en;//write "valid"
logic [ARRAY_ENTRY-1:0] write2_en;
logic [ARRAY_ENTRY-1:0] WB_en1;
logic [ARRAY_ENTRY-1:0] WB_en2;

logic [ARRAY_ENTRY-1:0] read11_en;//read "valid" 
logic [ARRAY_ENTRY-1:0] read12_en;
logic [ARRAY_ENTRY-1:0] read21_en;
logic [ARRAY_ENTRY-1:0] read22_en;

//read "valid"
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read11_valid_bit;
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read12_valid_bit;
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read21_valid_bit;
logic [ARRAY_ENTRY-1:0][OPRAND_WIDTH-1:0] read22_valid_bit;

//read and write index after decode
logic [ARRAY_ENTRY-1:0] index_valid11_write, index_valid12_write, index_valid21_write, index_valid22_write;
logic [ARRAY_ENTRY-1:0] index_read11, index_read12, index_read21, index_read22;

generate
for (genvar i=0;i<ARRAY_ENTRY;i++) begin

	assign write1_en[i] = write11_en_i && index_valid11_write[i];
	assign write2_en[i] = write12_en_i && index_valid12_write[i];
	assign WB_en1[i] = write21_en_i && index_valid21_write[i];
	assign WB_en2[i] = write22_en_i && index_valid22_write[i];
	
	assign read11_en[i] = read11_en_i && index_read11[i];
	assign read12_en[i] = read12_en_i && index_read12[i];
	assign read21_en[i] = read21_en_i && index_read21[i];
	assign read22_en[i] = read22_en_i && index_read22[i];
	
	//4 read 4 write
	ff_valid #(.DATA_WIDTH(OPRAND_WIDTH)) ff_valid 
								 (.clk,
								  .rst,
								  
								  .write11_en_i(write1_en[i]),
								  .write12_en_i(write2_en[i]),
								  .write21_en_i(WB_en1[i]),
								  .write22_en_i(WB_en2[i]),
								  
								  .read11_en_i(read11_en[i]),
								  .read12_en_i(read12_en[i]),
								  .read21_en_i(read21_en[i]),
								  .read22_en_i(read22_en[i]),
								  
								  //write "0" has priority than "1"
								  .data11_i(write11_data_i),
								  .data12_i(write12_data_i),
								  .data21_i(write21_data_i),
								  .data22_i(write22_data_i),
								  
								  .data11_o(read11_valid_bit[i]),
								  .data12_o(read12_valid_bit[i]),
								  .data21_o(read21_valid_bit[i]),
								  .data22_o(read22_valid_bit[i])
								  );
end
endgenerate

//write address Decoder
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_valid1
				    (.index_i(write11_addr_i),
			         .index_depth_o(index_valid11_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_valid2
				    (.index_i(write12_addr_i),
			         .index_depth_o(index_valid12_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_data1
				    (.index_i(write21_addr_i),
			         .index_depth_o(index_valid21_write)
					 );
					 
decoder #(.WIDTH(REGNAME_WIDTH)) decoder_data2
				    (.index_i(write22_addr_i),
			         .index_depth_o(index_valid22_write)
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
	  
//read valid MUX
mux #(.WIDTH(REGNAME_WIDTH),.WID(1)) mux_read11_valid
						(.index_i(read11_addr_i),
						 .data_i(read11_valid_bit),
						 .read_en_i(read11_en_i),
                         .data_o(read11_data_o),
						 .read_ready_o(read11_ready_o)
						 );
						 
mux #(.WIDTH(REGNAME_WIDTH),.WID(1)) mux_read12_valid
						(.index_i(read12_addr_i),
						 .data_i(read12_valid_bit),
						 .read_en_i(read12_en_i),
                         .data_o(read12_data_o),
						 .read_ready_o(read12_ready_o)
						 );

mux #(.WIDTH(REGNAME_WIDTH),.WID(1)) mux_read21_valid
						(.index_i(read21_addr_i),
						 .data_i(read21_valid_bit),
						 .read_en_i(read21_en_i),
                         .data_o(read21_data_o),
						 .read_ready_o(read21_ready_o)
						 );

mux #(.WIDTH(REGNAME_WIDTH),.WID(1)) mux_read22_valid
						(.index_i(read22_addr_i),
						 .data_i(read22_valid_bit),
						 .read_en_i(read22_en_i),
                         .data_o(read22_data_o),
						 .read_ready_o(read22_ready_o)
						 );	
						 
endmodule
