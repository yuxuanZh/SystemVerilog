module ff_2r_6w  #(parameter DATA_WIDTH = 32)(
				 input clk,
			     input rst,
	             input write1_en_i, write2_en_i, write3_en_i, write4_en_i, write5_en_i, write6_en_i,
				 input read1_en_i, read2_en_i, 
                 input [DATA_WIDTH-1:0] data1_i, data2_i, data3_i, data4_i, data5_i, data6_i,
			     output logic [DATA_WIDTH-1:0] data1_o, data2_o
				);
				
				logic [DATA_WIDTH-1:0] data_tmp;

//2-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b0}};
 end
 else begin
  if(write1_en_i) data_tmp <= data1_i; 
  else if(write2_en_i) data_tmp <= data2_i;
  else if(write3_en_i) data_tmp <= data3_i; 
  else if(write4_en_i) data_tmp <= data4_i;
  else if(write5_en_i) data_tmp <= data5_i; 
  else if(write6_en_i) data_tmp <= data6_i;
  else;
 end
end

//4-ported read
assign data1_o = read1_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data2_o = read2_en_i ? data_tmp : {DATA_WIDTH{1'b0}};

endmodule