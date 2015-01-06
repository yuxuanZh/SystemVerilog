module superscalar  #(parameter INSTR_WIDTH = 32,
		 parameter PC_WIDTH = 32,
		 parameter REGNAME_WIDTH = 5,
		 parameter OP_WIDTH = 7,
     parameter OPRAND_WIDTH = 32,
     parameter ARRAY_ENTRY = 32,
     parameter FUNC_WIDTH = 10,
     parameter IMM_WIDTH = 12)
  (ifc_test.dut d);

  ifc_dec_rf dec_rf();
  ifc_rob_rf rob_rf();
  ifc_rob_lsq rob_lsq();
  ifc_rob_dec rob_dec();
  ifc_rob_alu rob_alu();
  
  logic [OPRAND_WIDTH-1:0] address_alu_lsq;

  insdec #(.INSTR_WIDTH(INSTR_WIDTH),.PC_WIDTH(PC_WIDTH),
              .REGNAME_WIDTH(REGNAME_WIDTH),.OP_WIDTH(OP_WIDTH)) instr_dec
				(
					.instruction1_i(d.instruction1),
					.ins1_valid_i(d.ins1_valid),
					.PC1_i(d.PC_in1),
					.instruction2_i(d.instruction2),
					.ins2_valid_i(d.ins2_valid),
					.PC2_i(d.PC_in2),
					.rf(dec_rf.dec),
					.rob(rob_dec.dec)
        );

  regfile #(.OPRAND_WIDTH(OPRAND_WIDTH),.ARRAY_ENTRY(ARRAY_ENTRY),.REGNAME_WIDTH(REGNAME_WIDTH)) 
          regfile(
                  .clk(d.clk),
                  .rst(d.rst),
				          .dec(dec_rf.rf),
				          .rob(rob_rf.rf)
				          );


  rob #(.ROB_DEPTH(ARRAY_ENTRY),.OP_WIDTH(OP_WIDTH), 
           .FUNC_WIDTH(FUNC_WIDTH), .OPRAND_WIDTH(OPRAND_WIDTH),
		       .IMM_WIDTH(IMM_WIDTH), .REGNAME_WIDTH(REGNAME_WIDTH),
		       .ENTRY_WIDTH(REGNAME_WIDTH), .INS_WIDTH(INSTR_WIDTH),
           .PC_WIDTH(INSTR_WIDTH)) rob
     (.clk(d.clk),
		  .rst(d.rst),
		  .dec(rob_dec.rob),
		  .rf(rob_rf.rob),
		  .alu(rob_alu.rob),
		  .lsq(rob_lsq.rob),
		  .ROB_full_o(d.ROB_full),
		  .jump_PC_o(d.jump_PC),
		  .jump_en_o(d.jump_en),
		  .branch_PC_o(d.branch_PC),
		  .branch_en_o(d.branch_en),
		  .flush_en_o(d.flush_en),
		  .flush_PC_o(d.flush_PC)
		  );
//change
  alu alu(
          .alu_rob(rob_alu.alu),
          .address_o(address_alu_lsq)
                               );
/*
  lsq lsq(.clk(d.clk),
		  .rst(d.rst),
		  .rob(rob_lsq.lsq),
      .result_addr_i(address_alu_lsq),
		  .mem_signal(d.mem_signal),
		  .mem_address(d.mem_address),
		  .mem_store_value_o(d.mem_store_value),
		  .mem_load_value_i(d.mem_load_value)
		 );
*/

  lsq lsq(.clk(d.clk),
		  .rst(d.rst),
		  .rob(rob_lsq.lsq),
      .result_addr_i(address_alu_lsq),
		  .mem_load_valid_i(d.mem_load_valid),
      .mem_store_en_o(d.mem_store_en),
      .mem_load_en_o(d.mem_load_en),
      .mem_store_type_o(d.mem_store_type),
      .mem_load_type_o(d.mem_load_type),
		  .mem_store_addr_o(d.mem_store_addr),
      .mem_load_addr_o(d.mem_load_addr),
		  .mem_store_value_o(d.mem_store_value),
		  .mem_load_value_i(d.mem_load_value)
		 );

  assign d.WB_target1 = rob_rf.WB_target1;
  assign d.WB_data1   = rob_rf.WB_data1;
  assign d.WB_en1     = rob_rf.WB_en1;
  assign d.WB_target2 = rob_rf.WB_target2;
  assign d.WB_data2   = rob_rf.WB_data2;
  assign d.WB_en2     = rob_rf.WB_en2;

endmodule
