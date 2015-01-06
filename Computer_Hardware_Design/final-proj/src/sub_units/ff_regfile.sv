/****
 * This is a 4 read 2 write ff arrays
 *  - 
 */
module ff_regfile #(parameter DATA_WIDTH = 32)
			    ( 
				 input clk,
			     input rst,
	             input write1_en_i, write2_en_i,
				 input read11_en_i, read12_en_i, read21_en_i, read22_en_i,
                 input [DATA_WIDTH-1:0] data1_i, data2_i,
			     output logic [DATA_WIDTH-1:0] data11_o, data12_o, data21_o, data22_o
				 );
				 
				 logic [DATA_WIDTH-1:0] data_tmp;

//2-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b0}};
  end
 else begin
  if(write1_en_i) data_tmp <= data1_i; // we assume there's no WAW case
  else if(write2_en_i) data_tmp <= data2_i;
  else;
 end
end

//4-ported read
assign data11_o = read11_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data12_o = read12_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data21_o = read21_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data22_o = read22_en_i ? data_tmp : {DATA_WIDTH{1'b0}};

endmodule