interface ifc_rob_dec #(parameter INS=32)();

logic           ins1_valid;
logic           ins2_valid;
logic [INS-1:0] ins1;
logic [INS-1:0] ins2;
//new
logic [INS-1:0] PC1;
logic [INS-1:0] PC2;

modport dec (
		output ins1_valid, ins1,
		       ins2_valid, ins2,
           PC1, PC2
		);

modport rob (
		 input ins1_valid, ins1,
		       ins2_valid, ins2,
           PC1, PC2
		);

endinterface
