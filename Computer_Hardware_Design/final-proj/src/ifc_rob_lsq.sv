/**
 * The interface inside DUT
 *  - The interface to connect between ROB and LSQ
 */

interface ifc_rob_lsq #(parameter LSQ_INDEX_WIDTH = 5,
			parameter OPRAND_WIDTH = 32) ();

	//enqueue enqueue
	logic [2:0] ls_type1;
	logic ls_valid1;
	logic [LSQ_INDEX_WIDTH-1:0] ls_entry1;

	logic [2:0] ls_type2;
        logic ls_valid2;
        logic [LSQ_INDEX_WIDTH-1:0] ls_entry2;

	//issue signals
	logic [LSQ_INDEX_WIDTH-1:0] addr_entry;
	logic  addr_valid;
	logic [OPRAND_WIDTH-1:0] store_data;

	//commit signals
	logic load_commit_valid;
	logic [LSQ_INDEX_WIDTH-1:0] load_commit_entry;
	logic [OPRAND_WIDTH-1:0] load_data;
	//logic load_data_valid;
	logic [LSQ_INDEX_WIDTH-1:0] store_commit_entry;
	logic store_commit_valid;
 
  //flush
	logic flush_valid;
  logic [LSQ_INDEX_WIDTH-1:0] flush_entry;

	modport rob (output ls_type1, ls_valid1, ls_type2, ls_valid2, addr_entry, addr_valid,                      
                      load_commit_entry, load_commit_valid, store_data, store_commit_entry,
			                store_commit_valid,
		     input ls_entry1, ls_entry2, load_data, flush_valid, flush_entry
		    );	
	modport lsq (input ls_type1, ls_valid1, ls_type2, ls_valid2, addr_entry, addr_valid,
                     load_commit_entry, load_commit_valid,
                            store_data, store_commit_entry,
                            store_commit_valid,
                     output ls_entry1, ls_entry2, load_data, flush_valid, flush_entry
                    );  

endinterface
	

