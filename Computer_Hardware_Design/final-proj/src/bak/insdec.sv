module insdec
  #(parameter PC=16,
	parameter INS=32)
  (ifc_dec_rf.dec  rf,
   ifc_rob_dec.dec rob,
   input [INS-1:0] instruction1, 
   input           ins1_valid, 
   input [PC-1:0]  PC_in1,
   input [INS-1:0] instruction2,
   input           ins2_valid,
   input [PC-1:0]  PC_in2
  );

endmodule
