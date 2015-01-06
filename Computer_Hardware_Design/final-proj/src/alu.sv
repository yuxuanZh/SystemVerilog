`include "src/sub_units/alu_sub.sv"
`include "src/sub_units/alu_lsq_schedule.sv"

module alu #(parameter OPRAND_WIDTH = 32,
		     parameter OP_FUNC_WIDTH = 17)
  (
	ifc_rob_alu.alu alu_rob,
	output logic [OPRAND_WIDTH-1:0] address_o
  );
  
  logic [OPRAND_WIDTH-1:0] result1, result2;
  
  assign alu_rob.result1 = result1;
  assign alu_rob.result2 = result2;
  
  alu_sub #(.OPRAND_WIDTH(OPRAND_WIDTH),.OP_FUNC_WIDTH(OP_FUNC_WIDTH)) alu1
					(
						.oprand1_i(alu_rob.operand11), 
						.oprand2_i(alu_rob.operand12),
						.op_func_i(alu_rob.op_func1),
						.result_o(result1)
					);
					
  alu_sub #(.OPRAND_WIDTH(OPRAND_WIDTH),.OP_FUNC_WIDTH(OP_FUNC_WIDTH)) alu2
					(
						.oprand1_i(alu_rob.operand21), 
						.oprand2_i(alu_rob.operand22),
						.op_func_i(alu_rob.op_func2),
						.result_o(result2)
					);
					
  alu_lsq_schedule #(.OPRAND_WIDTH(OPRAND_WIDTH), .OP_WIDTH(7)) alu_lsq_schedule
	(
		.result1_i(result1), .result2_i(result2), 
		.op_func1_i(alu_rob.op_func1[6:0]), .op_func2_i(alu_rob.op_func2[6:0]),
		.address_o
	);

					
endmodule
