interface ifc_rob_alu #(
		parameter OPE=32,
		parameter FUNC=17) ();

  logic	[OPE-1:0] operand11;
  logic [OPE-1:0] operand12;
  logic [OPE-1:0] operand21;
  logic [OPE-1:0] operand22;
  logic [OPE-1:0] result1;
  logic [OPE-1:0] result2;
  logic [FUNC-1:0] op_func1;
  logic [FUNC-1:0] op_func2;

  modport alu(
		  input operand11, operand12, operand21,
		        operand22, op_func1, op_func2,
		  output result1, result2
		  );

  modport rob(
		  output operand11, operand12, operand21,
		         operand22, op_func1, op_func2,
		  input result1, result2
		  );
  
 // modport lsq(
	//	  input result1, result2
	//	  );

  endinterface

