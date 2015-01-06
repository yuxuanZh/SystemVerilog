/**
 * The interface inside DUT
 *  - The interface to connect between instruction decoder and register file
 */

interface ifc_dec_rf #(parameter REGNAME_WIDTH = 5) ();
	
	//target operand  write "valid" interface
	logic write1_en;
	logic write2_en;
	logic [REGNAME_WIDTH-1:0] write1_addr;
	logic [REGNAME_WIDTH-1:0] write2_addr; 

	//source operand read data req interface
	logic read11_en;
	logic read12_en;
	logic read21_en;
	logic read22_en;
	logic [REGNAME_WIDTH-1:0] read11_addr;
	logic [REGNAME_WIDTH-1:0] read12_addr;
	logic [REGNAME_WIDTH-1:0] read21_addr;
	logic [REGNAME_WIDTH-1:0] read22_addr;

	modport dec (output  write1_en, write2_en, write1_addr, write2_addr, 
		     	     read11_en, read12_en, read21_en, read22_en, read11_addr,
		     	     read12_addr, read21_addr, read22_addr
		    );

        modport rf (input  write1_en, write2_en, write1_addr, write2_addr,                      
                     	    read11_en, read12_en, read21_en, read22_en, read11_addr,                     
                     	    read12_addr, read21_addr, read22_addr                                        
                    );
endinterface
