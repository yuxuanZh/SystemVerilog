/**
 * Class of the register file simulator
 *  - The register file used to check the register file of DUT
 */

`ifndef CLASS_REGFILE_SV
`define CLASS_REGFILE_SV

class regfile;
   // Members of class
   rand bit [31:0] regs[32];
   rand bit        vlds[32];

   environment env;

   // Constructor
   function new(ref environment e);
      env = e;
   endfunction

   // Tasks of class
   task write(bit [4:0] idx, bit [31:0] value);
      regs[idx] = value;
      vlds[idx] = 1;
      //if (env.dbg_msg) $display("[dbg] fake_reg write %d 0x%h", idx, value);
   endtask

   task read(bit [4:0] idx, output bit [31:0] value, bit valid);
      value = regs[idx];
      valid = vlds[idx];
   endtask
   
   // Functions of class
   function on_reset(bit rst);
      if (rst) begin
         for (int i = 0; i < 32; i++) begin
            regs[i] = 0;
            vlds[i] = 1;
         end
      end
   endfunction

   function void print_rf;
         $display("Register File contents");
      for (int i = 0; i < 32; i++) begin
         $display ("index: %-2d, data: 0x%-8h, valid: %-1d", i, regs[i], vlds[i]);
      end
         $display("\n");
   endfunction

endclass

`endif
