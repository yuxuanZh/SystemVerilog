/**
 * The interface inside dut
 *  - The interface to connect between ROB and register file
 */

interface ifc_rob_rf #(parameter OPRAND_WIDTH = 32,
		       parameter REGNAME_WIDTH = 5) ();

	//source operand read data interface
	logic read11_valid_bit;
	logic read11_ready;
	logic [OPRAND_WIDTH-1:0] read11_data;

	logic read12_valid_bit;                                                                   
        logic read12_ready;                                                                        
        logic [OPRAND_WIDTH-1:0] read12_data;
	
	logic read21_valid_bit;                                                                   
        logic read21_ready;                                                                        
        logic [OPRAND_WIDTH-1:0] read21_data;

	logic read22_valid_bit;                                                                   
        logic read22_ready;                                                                        
        logic [OPRAND_WIDTH-1:0] read22_data;

	//target operand write data interface
	logic WB_en1;
	logic [REGNAME_WIDTH-1:0] WB_target1;
	logic [OPRAND_WIDTH-1:0] WB_data1;

	logic WB_en2;
        logic [REGNAME_WIDTH-1:0] WB_target2;
        logic [OPRAND_WIDTH-1:0] WB_data2;

modport rob (input read11_valid_bit, read11_ready, read11_data, 
		   read12_valid_bit, read12_ready, read12_data,
		   read21_valid_bit,  read21_ready, read21_data,
		   read22_valid_bit, read22_ready, read22_data,
	     output WB_en1, WB_target1, WB_data1, WB_en2, WB_target2, WB_data2
 	    );

modport rf (output read11_valid_bit, read11_ready, read11_data, 
                   read12_valid_bit, read12_ready, read12_data,
                   read21_valid_bit,  read21_ready, read21_data,
                   read22_valid_bit, read22_ready, read22_data,
             input WB_en1, WB_target1, WB_data1, WB_en2, WB_target2, WB_data2
            );

endinterface
