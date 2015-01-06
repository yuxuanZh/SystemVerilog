/****
 * This is a 4 read 4 write ff arrays
 *  - 
 */
module ff_3r_3w #(parameter DATA_WIDTH = 32)
			    ( 
				 input clk,
			     input rst,
	             input write1_en_i, write2_en_i, write3_en_i,
				 input read1_en_i, read2_en_i, read3_en_i,
                 input [DATA_WIDTH-1:0] data1_i, data2_i, data3_i,
			     output logic [DATA_WIDTH-1:0] data1_o, data2_o, data3_o
				 );
				 
				 logic [DATA_WIDTH-1:0] data_tmp;

//2-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b0}};
  end
 else begin
  if(write1_en_i) data_tmp <= data1_i; //write "0" when enqueue 
  else if(write2_en_i) data_tmp <= data2_i;//??
  else if(write3_en_i) data_tmp <= data3_i;//when write "1" when commit and write "0" when enqueue happen at the same time
  else;
 end
end

//4-ported read
assign data1_o = read1_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data2_o = read2_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data3_o = read3_en_i ? data_tmp : {DATA_WIDTH{1'b0}};

endmodule
