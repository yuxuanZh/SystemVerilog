
/****
 * This is a 4 read 4 write ff arrays
 *  - 
 */
module ff_valid #(parameter DATA_WIDTH = 32)
			    ( 
				 input clk,
			     input rst,
	             input write11_en_i, write12_en_i, write21_en_i, write22_en_i,
				 input read11_en_i, read12_en_i, read21_en_i, read22_en_i,
                 input [DATA_WIDTH-1:0] data11_i, data12_i, data21_i, data22_i,
			     output logic [DATA_WIDTH-1:0] data11_o, data12_o, data21_o, data22_o
				 );
				 
				 logic [DATA_WIDTH-1:0] data_tmp;

//2-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b1}};
  end
 else begin
  if(write11_en_i) data_tmp <= data11_i; //write "0" when enqueue 
  else if(write12_en_i) data_tmp <= data12_i;//??
  else if(write21_en_i) data_tmp <= data21_i;//when write "1" when commit and write "0" when enqueue happen at the same time
  else if(write22_en_i) data_tmp <= data22_i;//No WAW dep
  else data_tmp <= data_tmp;
 end
end

//4-ported read
assign data11_o = read11_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data12_o = read12_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data21_o = read21_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data22_o = read22_en_i ? data_tmp : {DATA_WIDTH{1'b0}};

endmodule
