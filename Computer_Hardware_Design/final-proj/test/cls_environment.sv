/**
 * Class of environement
 *  - Configure the environment and test cases
 */

`ifndef CLASS_ENVIRONMENT_SV
`define CLASS_ENVIRONMENT_SV

class environment;
   // Members of class
   bit dbg_msg;   // Debug message flag
   bit ass_chk;
   bit verbose;
   int cycles;    // Test cycles
   bit auto_config;
   int random_seed;  // Random seed
   bit data_ctrl;
   bit data_depend;
   bit mem_ctrl;
   bit mem_depend;
   bit auto_mem_data;
   bit preload_mem;
   bit per_check;

   real d_rst_real;
   real d_noop_real;
   real d_op_real;
   real d_alu_real;
   real d_ls_real;
   real d_bj_real;

   int d_rst_cycle;
   int d_noop_cycle;
   int d_op_cycle;
   int d_alu_cycle;
   int d_ls_cycle;
   int d_bj_cycle;

   rand bit [4:0] m_reg_rd;
   rand bit [4:0] m_reg_r1;
   rand bit [4:0] m_reg_r2;

   rand bit [11:0] m_imm_12;
   rand bit [20:0] m_imm_20;

   // Constructor - Set up default environment
   function new();
      dbg_msg = 0;   // Turn on debug message during development
      ass_chk = 0;
      verbose = 0;
      cycles = 10000;
      auto_config = 0;  // Turn off auto config during development
      random_seed = 0;
      data_ctrl = 0;
      data_depend = 0;
      mem_ctrl = 0;
      mem_depend = 0;
      auto_mem_data = 1;
      preload_mem = 1;
      per_check = 0;

      d_rst_real = 0.0002;
      d_noop_real = 0.001;
      d_op_real = 0.999;
      d_alu_real = 0.8;
      d_ls_real = 0.15;
      d_bj_real = 0.05;

      d_rst_cycle = d_rst_real * cycles;
      d_noop_cycle = d_noop_real * cycles;
      d_op_cycle = d_op_real * cycles;
      d_alu_cycle = d_alu_real * cycles;
      d_ls_cycle = d_ls_real * cycles;
      d_bj_cycle = d_bj_real * cycles;

      m_reg_rd = 5'b11111;
      m_reg_r1 = 5'b11111;
      m_reg_r2 = 5'b11111;

      m_imm_12 = 12'hfff;
      m_imm_20 = 20'hfffff;
   endfunction

   // Tasks of class

   // Functions of class
   function void set_config(string config_file);
      int retval, file = 0;
      string item, option;

      file = $fopen(config_file, "r");
      if (file) begin
         $display("Read config from %s", config_file);
         while (!$feof(file)) begin
            retval = $fscanf(file, "%s %s", item, option); 
            case (item)
               "debug_msg": dbg_msg = option.atoi();
               "assert_check": ass_chk = option.atoi();
               "verbose": verbose = option.atoi();
               "cycles": cycles = option.atoi();
               "auto_config": auto_config = option.atoi();
               "random_seed": random_seed = option.atoi();
               "data_control": data_ctrl = option.atoi();
               "data_dependency": data_depend = option.atoi();
               "mem_control": mem_ctrl = option.atoi();
               "mem_dependency": mem_depend = option.atoi();
               "auto_memory_data": auto_mem_data = option.atoi();
               "preload_memory": preload_mem = option.atoi();
               "density_reset": d_rst_real = option.atoreal();
               "density_noop": d_noop_real = option.atoreal();
               "density_ls": d_ls_real = option.atoreal();
               "density_bj": d_bj_real = option.atoreal();
               "mask_reg_rd": m_reg_rd = option.atohex();
               "mask_reg_r1": m_reg_r1 = option.atohex();
               "mask_reg_r2": m_reg_r2 = option.atohex();
               "mask_imm_12": m_imm_12 = option.atohex();
               "mask_imm_20": m_imm_20 = option.atohex();
               default:;
            endcase
         end
      end

      /* Process the config */
      d_op_real = 1.0 - d_noop_real;
      d_alu_real = 1.0 - (d_ls_real + d_bj_real);

      d_rst_cycle = d_rst_real * cycles;
      d_noop_cycle = d_noop_real * cycles;
      d_op_cycle = d_op_real * cycles;
      d_alu_cycle = d_alu_real * cycles;
      d_ls_cycle = d_ls_real * cycles;
      d_bj_cycle = d_bj_real * cycles;

      if (!auto_config)
         this.rand_mode(0);

      if (data_ctrl && data_depend == 0 &&
            d_noop_cycle == 0 && d_alu_cycle == cycles)
         per_check = 1;
      else
         per_check = 0;

   endfunction

   function void print_config();
      $display("Current environmental parameters:");
      $display("debug_msg: %d", dbg_msg);
      $display("assert_check: %d", ass_chk);
      $display("verbose: %d", verbose);
      $display("cycles: %d", cycles);
      $display("auto_config: %d", auto_config);
      $display("random_seed: %d", random_seed);
      $display("data_control: %d", data_ctrl);
      $display("data_dependency: %d", data_depend);
      $display("mem_control: %d", mem_ctrl);
      $display("mem_dependency: %d", mem_depend);
      $display("auto_memory_data: %d", auto_mem_data);
      $display("preload_memory: %d", preload_mem);
      $display("performance_check: %d", per_check);

      $display("density_reset: %f", d_rst_real);
      $display("density_noop: %f", d_noop_real);
      $display("density_op: %f", d_op_real);
      $display("density_alu: %f", d_alu_real);
      $display("density_ls: %f", d_ls_real);
      $display("density_bj: %f", d_bj_real);

      $display("mask_reg_rd: 0x%h", m_reg_rd);
      $display("mask_reg_r1: 0x%h", m_reg_r1);
      $display("mask_reg_r2: 0x%h", m_reg_r2);
      $display("mask_imm_12: 0x%h", m_imm_12);
      $display("mask_imm_20: 0x%h", m_imm_20);
   endfunction

   function void dbg(string str);
      if (dbg_msg)
         $display("%t: [dbg] %s", $realtime, str);
   endfunction

endclass

`endif
