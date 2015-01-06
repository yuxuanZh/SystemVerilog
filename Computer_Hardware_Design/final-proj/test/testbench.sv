/**
 * Testbench of the design
 */
`include "test/cls_environment.sv"
`include "test/cls_memory.sv"
`include "test/cls_regfile.sv"
`include "test/cls_transaction.sv"
`include "test/cls_goldenmodel.sv"

program automatic bench (ifc_test.bench ds);
   environment env;
   memory mem;
   regfile rf;
   transaction t;
   goldenmodel gm;

   instruction_t i1;
   instruction_t i2;

   chkres_t chk;

   bit [31:0] ldata;
   bit        valid;
   bit        last_rst;
   
   bit tb_len;
   bit [1:0] tb_ltype;
   bit [31:0] tb_laddr;
   bit [31:0] tb_ldata;
   bit tb_lvalid;

   int i = 1;

   initial begin
      // Set up environment
      env = new();
      env.set_config("config.txt");
      assert(env.randomize());
      env.print_config();

      // Set up memory
      mem = new(env);

      // Set up regfile
      rf = new(env);

      // Set up golden model
      gm = new(env, rf);

      // Set up transaction
      t = new(env);

      // Warm up
      ds.cb.rst <= 1;
      @(ds.cb);

      // Pre-load
      if (env.preload_mem) begin
         t.dist_noop.constraint_mode(0);
         t.dist_optype.constraint_mode(0);
         t.c_force_lw.constraint_mode(1);
         repeat (31) begin
            if (env.dbg_msg) $display("=========================== Pre-loading Cycle starts ===========================");
            t.do_force_rd(1, i);
            assert(t.randomize());
            i1 = t.i1;

            ds.cb.rst <= 0;
            ds.cb.PC_in1 <= i1.PC;
            ds.cb.instruction1 <= i1.instr;
            ds.cb.ins1_valid <= i1.valid;
            ds.cb.PC_in2 <= 0;
            ds.cb.instruction2 <= 0;
            ds.cb.ins2_valid <= 0;
            if (env.dbg_msg)
               $display("%d %d 0x%h %d %d 0x%h %d", t.rst, i1.PC, i1.instr, i1.valid, i2.PC, i2.instr, i2.valid);

            gm.load_ins(i1, tb_len, tb_ltype, tb_laddr);
            mem.load(tb_len, tb_ltype, tb_laddr, tb_ldata, tb_lvalid);
            if (tb_lvalid) gm.update_load(i1, tb_laddr, tb_ldata);

            @(ds.cb);
            if (env.dbg_msg)
               $display("%d|%d %d|%d %d|%d %d|%d 0x%h %d|%d 0x%h %d|%d %b 0x%h 0x%h|%d %b %h",
                        ds.cb.ROB_full, ds.cb.jump_PC, ds.cb.jump_en, ds.cb.branch_PC, ds.cb.branch_en, ds.cb.flush_PC, ds.cb.flush_en,
                        ds.cb.WB_target1, ds.cb.WB_data1, ds.cb.WB_en1, ds.cb.WB_target2, ds.cb.WB_data2, ds.cb.WB_en2,
                        ds.cb.mem_store_en, ds.cb.mem_store_type, ds.cb.mem_store_addr, ds.cb.mem_store_value,
                        ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr);
            //commit: write-back check
            chk = gm.wb_check(t.rst, ds.cb.WB_en1, ds.cb.WB_target1, ds.cb.WB_data1,
                              ds.cb.WB_en2, ds.cb.WB_target2, ds.cb.WB_data2);
            if (env.ass_chk) chk_assert(chk, "Write-back check failed");
            //load instruction
            mem.load(ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr,
                     ldata, valid);
            ds.cb.mem_load_value <= ldata;
            ds.cb.mem_load_valid <= valid;

            if (ds.cb.WB_en1) t.release_rd(ds.cb.WB_target1);
            if (ds.cb.WB_en2) t.release_rd(ds.cb.WB_target2);
            i++;
         end

         // For simplicity, don't check and wait for pre-loading complete
         repeat (9) begin
            if (env.dbg_msg) $display("============================= Waiting Cycle starts =============================");
            ds.cb.rst <= 0;
            ds.cb.PC_in1 <= 0;
            ds.cb.instruction1 <= 0;
            ds.cb.ins1_valid <= 0;
            ds.cb.PC_in2 <= 0;
            ds.cb.instruction2 <= 0;
            ds.cb.ins2_valid <= 0;
            if (env.dbg_msg)
               $display("%d %d 0x%h %d %d 0x%h %d", t.rst, i1.PC, i1.instr, i1.valid, i2.PC, i2.instr, i2.valid);
            @(ds.cb);
            if (env.dbg_msg)
               $display("%d|%d %d|%d %d|%d %d|%d 0x%h %d|%d 0x%h %d|%d %b 0x%h 0x%h|%d %b %h",
                        ds.cb.ROB_full, ds.cb.jump_PC, ds.cb.jump_en, ds.cb.branch_PC, ds.cb.branch_en, ds.cb.flush_PC, ds.cb.flush_en,
                        ds.cb.WB_target1, ds.cb.WB_data1, ds.cb.WB_en1, ds.cb.WB_target2, ds.cb.WB_data2, ds.cb.WB_en2,
                        ds.cb.mem_store_en, ds.cb.mem_store_type, ds.cb.mem_store_addr, ds.cb.mem_store_value,
                        ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr);
            //commit: write-back check
            chk = gm.wb_check(t.rst, ds.cb.WB_en1, ds.cb.WB_target1, ds.cb.WB_data1,
                              ds.cb.WB_en2, ds.cb.WB_target2, ds.cb.WB_data2);
            if (env.ass_chk) chk_assert(chk, "Write-back check failed");
            //load instruction
            mem.load(ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr,
                     ldata, valid);
            ds.cb.mem_load_value <= ldata;
            ds.cb.mem_load_valid <= valid;

            if (ds.cb.WB_en1) t.release_rd(ds.cb.WB_target1);
            if (ds.cb.WB_en2) t.release_rd(ds.cb.WB_target2);
         end

         t.dist_noop.constraint_mode(1);
         t.dist_optype.constraint_mode(1);
         t.do_force_rd(0, 0);
      end

      // Prepare for the test
      env.preload_mem = 0;
      t.c_force_lw.constraint_mode(0);
      assert(t.rd_unused.size() == 31) else $error("All rd should be usable");
      assert(t.rd_used.size() == 0) else $error("There should be no rd used");
      t.rst = 0;

      $display("\n%t: %s", $realtime, "Start to run the test");

      repeat (env.cycles) begin
         if (env.dbg_msg) $display("================================= Cycle starts =================================");
         else $display("");
         // Randomize input data
         last_rst = t.rst;
         // 1st instruction
         t.do_force_reset(0, 0);
		 if(last_rst)
		 t.do_force_invalid(1);
         assert(t.randomize());
         i1 = t.i1;
		 if(!i1.valid)
		 t.do_force_invalid(1);
         // 2nd instruction
         t.do_force_reset(1, t.rst);
         assert(t.randomize());
         i2 = t.i1;

         // Update status (pre-stage if needed)

         // Drive input data
         $display("%t: %s", $realtime, "Driving New Values");
         ds.cb.rst <= t.rst;
         ds.cb.PC_in1 <= i1.PC;
         ds.cb.instruction1 <= i1.instr;
         ds.cb.ins1_valid <= i1.valid;
         ds.cb.PC_in2 <= i2.PC;
         ds.cb.instruction2 <= i2.instr;
         ds.cb.ins2_valid <= i2.valid;

         if (env.dbg_msg)
            $display("%d %d 0x%h %d %d 0x%h %d", t.rst, i1.PC, i1.instr, i1.valid, i2.PC, i2.instr, i2.valid);

         // Clocking
         @(ds.cb);

         if (env.dbg_msg)
            $display("%d|%d %d|%d %d|%d %d|%d 0x%h %d|%d 0x%h %d|%d %b 0x%h 0x%h|%d %b %h",
                     ds.cb.ROB_full, ds.cb.jump_PC, ds.cb.jump_en, ds.cb.branch_PC, ds.cb.branch_en, ds.cb.flush_PC, ds.cb.flush_en,
                     ds.cb.WB_target1, ds.cb.WB_data1, ds.cb.WB_en1, ds.cb.WB_target2, ds.cb.WB_data2, ds.cb.WB_en2,
                     ds.cb.mem_store_en, ds.cb.mem_store_type, ds.cb.mem_store_addr, ds.cb.mem_store_value,
                     ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr);
		 
		 //golden model update
         gm.on_reset(last_rst);
         rf.on_reset(last_rst);

		 gm.update(i1); 
		 gm.load_ins(i1, tb_len, tb_ltype, tb_laddr);
		 mem.load(tb_len, tb_ltype, tb_laddr, tb_ldata, tb_lvalid);
		 if(tb_lvalid) gm.update_load(i1, tb_laddr, tb_ldata);

		 gm.update(i2); 
		 gm.load_ins(i2, tb_len, tb_ltype, tb_laddr);
		 mem.load(tb_len, tb_ltype, tb_laddr, tb_ldata, tb_lvalid);
		 if(tb_lvalid) gm.update_load(i2, tb_laddr, tb_ldata);
		 
         //issue: load instruction
         mem.load(ds.cb.mem_load_en, ds.cb.mem_load_type, ds.cb.mem_load_addr,
                  ldata, valid);
         mem.store(ds.cb.mem_store_en, ds.cb.mem_store_type,
                  ds.cb.mem_store_addr, ds.cb.mem_store_value);
         ds.cb.mem_load_value <= ldata;
         ds.cb.mem_load_valid <= valid;
		 
         if (env.verbose) rf.print_rf;
         if (env.verbose) gm.print_queue;

         // Result check
         $display("%t: %s", $realtime, "Check results");

         chk = gm.reset_check(last_rst, ds.cb.branch_en, ds.cb.jump_en, ds.cb.flush_en,
                              ds.cb.WB_en1, ds.cb.WB_en2,
                              ds.cb.mem_store_en, ds.cb.mem_load_en);
         if (env.ass_chk) chk_assert(chk, "Reset check failed");
		 
		 //issue: branch/jump check
         chk = gm.branch_check(last_rst, ds.cb.branch_en, ds.cb.branch_PC, ds.cb.jump_PC);
         if (env.ass_chk) chk_assert(chk, "Branch");
         chk = gm.jump_check(t.rst, ds.cb.jump_en, ds.cb.jump_PC, ds.cb.branch_PC);
         if (env.ass_chk) chk_assert(chk, "Jump check failed");
		 
		 //commit: write-back check
         chk = gm.wb_check(last_rst, ds.cb.WB_en1, ds.cb.WB_target1, ds.cb.WB_data1,
                           ds.cb.WB_en2, ds.cb.WB_target2, ds.cb.WB_data2);
         if (env.ass_chk) chk_assert(chk, "Write-back check failed");
					 
		 //commit: store check
         chk = gm.store_check(last_rst, ds.cb.mem_store_en, ds.cb.mem_store_type, ds.cb.mem_store_addr, ds.cb.mem_store_value);
         if (env.ass_chk) chk_assert(chk, "Store check failed");

         chk = gm.ROBfull_check(last_rst, ds.cb.ROB_full);
         if (env.ass_chk) chk_assert(chk, "ROB full check failed");

         // performance
         chk = gm.per_check(last_rst);
         if (env.ass_chk) chk_assert(chk, "Performance check failed");

         // Update status (post-stage if needed)
         if (ds.cb.WB_en1) t.release_rd(ds.cb.WB_target1);
         if (ds.cb.WB_en2) t.release_rd(ds.cb.WB_target2);

         if (ds.cb.ROB_full)
            t.do_force_invalid(1);
         else
            t.do_force_invalid(0);

         if (env.verbose) gm.print_queue;
      end

      $finish;
   end

endprogram
