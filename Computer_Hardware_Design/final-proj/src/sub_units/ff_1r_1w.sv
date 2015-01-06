module ff_1r_1w  #(parameter DATA_WIDTH = 32)(
				 input clk,
			     input rst,
	             input write_en_i,
				 input read_en_i, 
                 input [DATA_WIDTH-1:0] data_i, 
			     output logic [DATA_WIDTH-1:0] data_o
				);
				
				logic [DATA_WIDTH-1:0] data_tmp;

//1-ported synchronous write				 
always_ff @(posedge clk) begin
 if(rst) begin
  data_tmp <= {DATA_WIDTH{1'b0}};
 end
 else begin
  if(write_en_i) data_tmp <= data_i; 
  else;

 end
end

//1-ported read
assign data_o = read_en_i ? data_tmp : {DATA_WIDTH{1'b0}};


endmodule