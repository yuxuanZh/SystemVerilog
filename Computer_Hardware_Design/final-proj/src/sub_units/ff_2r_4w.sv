module ff_2r_4w  #(parameter DATA_WIDTH = 32)(
				 input clk,
			     input rst,
	             input write11_en_i, write12_en_i, write21_en_i, write22_en_i,
				 input read1_en_i, read2_en_i, 
                 input [DATA_WIDTH-1:0] data11_i, data12_i, data21_i, data22_i, 
			     output logic [DATA_WIDTH-1:0] data1_o, data2_o
				);
				
				logic [DATA_WIDTH-1:0] data_tmp;

//2-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b0}};
 end
 else begin
  if(write11_en_i) data_tmp <= data11_i; 
  else if(write12_en_i) data_tmp <= data12_i;
  else if(write21_en_i) data_tmp <= data21_i; 
  else if(write22_en_i) data_tmp <= data22_i;
  else;
 end
end

//4-ported read
assign data1_o = read1_en_i ? data_tmp : {DATA_WIDTH{1'b0}};
assign data2_o = read2_en_i ? data_tmp : {DATA_WIDTH{1'b0}};

endmodule