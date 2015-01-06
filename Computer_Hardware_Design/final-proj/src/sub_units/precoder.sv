module precoder #(parameter WIDTH = 5,
				  parameter DEPTH = 1<<WIDTH)
	(
	 input  [WIDTH-1:0] head,
	 input  [DEPTH-1:0] search_valid_i,
	 output logic [DEPTH-1:0] search_valid_o
	);

logic [WIDTH-1:0] i;

always_comb begin
	for (int iter=0; iter<32; iter++) begin
		i = iter + head;
		search_valid_o[iter] = search_valid_i[i];
	end
end

endmodule
