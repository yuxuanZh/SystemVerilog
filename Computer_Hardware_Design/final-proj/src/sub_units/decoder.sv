module decoder #(parameter WIDTH = 5,//index bit width
			     parameter DEPTH = 1<<WIDTH)//number of output
				    (input [WIDTH-1:0] index_i,
			             output logic [DEPTH-1:0] index_depth_o);
always_comb begin
 for(int i=0;i<DEPTH;i++)
 if(index_i==i) index_depth_o = 1<<index_i;
 end
endmodule
 
