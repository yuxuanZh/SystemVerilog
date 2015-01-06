module alu_lsq_schedule #(parameter OPRAND_WIDTH = 32,
				   parameter OP_WIDTH = 7)
	(
		input [OPRAND_WIDTH-1:0] result1_i, result2_i, 
		input [OP_WIDTH-1:0] op_func1_i, op_func2_i,
		output logic [OPRAND_WIDTH-1:0] address_o
	);

	parameter STORE = 7'b0100011, LOAD = 7'b0000011;
	
always_comb begin
	if(op_func1_i == STORE || op_func1_i == LOAD) address_o = result1_i;
	else if(op_func2_i == STORE || op_func2_i == LOAD) address_o = result2_i;
	else address_o = 32'd0;
end

endmodule