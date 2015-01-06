/**
 * Class of the memory simulator
 *  - The simulated memory for DUT
 */

`ifndef CLASS_MEMORY_SV
`define CLASS_MEMORY_SV

class memory;
   // Members of class
   bit [7:0] mem[bit [31:0]];

   environment env;

   // Constructor
   function new(ref environment e);
      env = e;
   endfunction

   // Tasks of class
   task store(bit mem_store_en, bit [1:0] mem_store_type,
      bit [31:0] mem_store_addr, bit [31:0] mem_store_value);
      if (env.dbg_msg) $display("MEM store: %d %b %h %h",
                                 mem_store_en, mem_store_type,
                                 mem_store_addr, mem_store_value);
      if (mem_store_en) begin
		 if(mem_store_type[1] == 1) begin //store word
		    mem[mem_store_addr+32'd3] = mem_store_value[31:24];
		    mem[mem_store_addr+32'd2] = mem_store_value[23:16];
		    mem[mem_store_addr+32'd1] = mem_store_value[15:8];
		 end
		 
		 if(mem_store_type[0] == 1) //store word/half-word
		    mem[mem_store_addr+32'd1] = mem_store_value[15:8];
		 
         mem[mem_store_addr] = mem_store_value[7:0]; //store word/half-word/byte
	  end
   endtask

   task load(bit mem_load_en, bit [1:0] mem_load_type, bit [31:0] mem_load_addr,
      output bit [31:0] mem_load_value, bit mem_load_valid);

      if (env.dbg_msg) $display("MEM load: %d %b %h",
                                 mem_load_en, mem_load_type, mem_load_addr);
      if (mem_load_en) begin
	  
	     mem_load_valid = 1;
		 
	     if(mem_load_type[1] == 1) begin  //load word
			if (mem.exists(mem_load_addr+32'd3)) begin
               mem_load_value[31:24] = mem[mem_load_addr+32'd3];
            end else if (env.auto_mem_data) begin
               mem[mem_load_addr+32'd3] = $unsigned($random());
               mem_load_value[31:24] = mem[mem_load_addr+32'd3];
               if (env.dbg_msg) $display("[dbg] Data 0x%-h is automatically generated for load", mem_load_value[31:24]);
            end else begin
			   mem_load_value[31:24] = 8'd0;
            end
		 
            if(mem.exists(mem_load_addr+32'd2)) begin
               mem_load_value[23:16] = mem[mem_load_addr+32'd2];
            end else if (env.auto_mem_data) begin
               mem[mem_load_addr+32'd2] = $unsigned($random());
               mem_load_value[23:16] = mem[mem_load_addr+32'd2];
               if (env.dbg_msg) $display("[dbg] Data 0x%-h is automatically generated for load", mem_load_value[23:16]);
            end else begin
			   mem_load_value[23:16] = 8'd0;
            end	

            if(mem.exists(mem_load_addr+32'd1)) begin
               mem_load_value[15:8] = mem[mem_load_addr+32'd1];
            end else if (env.auto_mem_data) begin
               mem[mem_load_addr+32'd1] = $unsigned($random());
               mem_load_value[15:8] = mem[mem_load_addr+32'd1];
               if (env.dbg_msg) $display("[dbg] Data 0x%-h is automatically generated for load", mem_load_value[23:16]);
            end else begin
			   mem_load_value[15:8] = 8'd0;
            end
        end

        if(mem_load_type[0] == 1) begin  //load word/half-word
           if (mem.exists(mem_load_addr+32'd1)) begin
              mem_load_value[15:8] = mem[mem_load_addr+32'd1];
           end else if (env.auto_mem_data) begin
              mem[mem_load_addr+32'd1] = $unsigned($random());
              mem_load_value[15:8] = mem[mem_load_addr+32'd1];
              if (env.dbg_msg) $display("[dbg] Data 0x%-h is automatically generated for load", mem_load_value[15:8]);
           end else begin
		      mem_load_value[15:8] = 8'd0;
           end        
		end
		
           if(mem.exists(mem_load_addr)) begin  //load word/half-word/byte
              mem_load_value[7:0] = mem[mem_load_addr];
           end else if (env.auto_mem_data) begin
              mem[mem_load_addr] = $unsigned($random());
              mem_load_value[7:0] = mem[mem_load_addr];
              if (env.dbg_msg) $display("[dbg] Data 0x%-h is automatically generated for load", mem_load_value[7:0]);
           end else begin
		      mem_load_value[7:0] = 8'd0;
           end 		
		 
      end else begin
         mem_load_valid = 0;
      end
   endtask

   // Functions of class

endclass

`endif
