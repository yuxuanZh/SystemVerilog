module mux #(parameter WIDTH = 5,//index bit width
                 parameter WID = 32,// data bit wid
                 parameter DEPTH = 1<<WIDTH)//number of input entry
						(
						 input [WIDTH-1:0] index_i,
						 input [DEPTH-1:0] [WID-1:0] data_i,
						 input read_en_i,
                         output logic [WID-1:0] data_o,
						 output logic read_ready_o
						 );
always_comb begin
  for(int i=0;i<DEPTH;i++)
	if(index_i==i && read_en_i) begin 
		data_o = data_i[i];
		read_ready_o = '1;
		break;// need to break;
		end
	else begin 
		data_o = {WID{'0}};
		read_ready_o = '0;
		end
 end
endmodule
