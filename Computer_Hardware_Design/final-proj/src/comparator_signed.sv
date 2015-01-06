//modified @12_18
module comparator_signed #(parameter DATA_WIDTH = 32) 
						(
						 input [DATA_WIDTH-1:0] oprand1_i, oprand2_i,
						 output logic res_o //set 1 if rs1 < rs2, otherwise
						);
	always_comb begin
	 if(oprand1_i[DATA_WIDTH-1] < oprand2_i[DATA_WIDTH-1]) res_o = '0;//rs1 = 0 && rs2 = 1
	 else if(oprand1_i[DATA_WIDTH-1] > oprand2_i[DATA_WIDTH-1]) res_o = '1;
	 else begin
	       if((oprand1_i[DATA_WIDTH-2:0] < oprand2_i[DATA_WIDTH-2:0])) res_o = '1;
		   else res_o = '0;	
    end		   
		   /*
	       for(int i=DATA_WIDTH-2;i>=0;i--)
		    if(oprand1_i[i]<oprand2_i[i]) begin
				res_o = '1;
				break;
			   end 
			 else if(oprand1_i[i]>oprand2_i[i]) begin
				res_o = '0;
				break;
			   end 
			 else res_o = '0;
		   end
		   */
	 end
endmodule