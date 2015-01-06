module pencoder #(parameter WIDTH = 6,//output width
		     parameter DEPTH = 1<<WIDTH-1)//number of inputs
 		           	(input [DEPTH-1:0] search_valid_i,
				output logic [WIDTH-1:0] search_index_o);

always_comb begin//return the *first* matched index after parallel search
 casex(search_valid_i)
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxx1: search_index_o = 6'd0;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xx10: search_index_o = 6'd1;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_x100: search_index_o = 6'd2;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_1000: search_index_o = 6'd3;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxx1_0000: search_index_o = 6'd4;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xx10_0000: search_index_o = 6'd5;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_x100_0000: search_index_o = 6'd6;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxxx_1000_0000: search_index_o = 6'd7;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xxx1_0000_0000: search_index_o = 6'd8;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_xx10_0000_0000: search_index_o = 6'd9;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_x100_0000_0000: search_index_o = 6'd10;
 32'bxxxx_xxxx_xxxx_xxxx_xxxx_1000_0000_0000: search_index_o = 6'd11;
 32'bxxxx_xxxx_xxxx_xxxx_xxx1_0000_0000_0000: search_index_o = 6'd12;
 32'bxxxx_xxxx_xxxx_xxxx_xx10_0000_0000_0000: search_index_o = 6'd13;
 32'bxxxx_xxxx_xxxx_xxxx_x100_0000_0000_0000: search_index_o = 6'd14;
 32'bxxxx_xxxx_xxxx_xxxx_1000_0000_0000_0000: search_index_o = 6'd15;
 32'bxxxx_xxxx_xxxx_xxx1_0000_0000_0000_0000: search_index_o = 6'd16;
 32'bxxxx_xxxx_xxxx_xx10_0000_0000_0000_0000: search_index_o = 6'd17;
 32'bxxxx_xxxx_xxxx_x100_0000_0000_0000_0000: search_index_o = 6'd18;
 32'bxxxx_xxxx_xxxx_1000_0000_0000_0000_0000: search_index_o = 6'd19;
 32'bxxxx_xxxx_xxx1_0000_0000_0000_0000_0000: search_index_o = 6'd20;
 32'bxxxx_xxxx_xx10_0000_0000_0000_0000_0000: search_index_o = 6'd21;
 32'bxxxx_xxxx_x100_0000_0000_0000_0000_0000: search_index_o = 6'd22;
 32'bxxxx_xxxx_1000_0000_0000_0000_0000_0000: search_index_o = 6'd23;
 32'bxxxx_xxx1_0000_0000_0000_0000_0000_0000: search_index_o = 6'd24;
 32'bxxxx_xx10_0000_0000_0000_0000_0000_0000: search_index_o = 6'd25;
 32'bxxxx_x100_0000_0000_0000_0000_0000_0000: search_index_o = 6'd26;
 32'bxxxx_1000_0000_0000_0000_0000_0000_0000: search_index_o = 6'd27;
 32'bxxx1_0000_0000_0000_0000_0000_0000_0000: search_index_o = 6'd28;
 32'bxx10_0000_0000_0000_0000_0000_0000_0000: search_index_o = 6'd29;
 32'bx100_0000_0000_0000_0000_0000_0000_0000: search_index_o = 6'd30;
 32'b1000_0000_0000_0000_0000_0000_0000_0000: search_index_o = 6'd31;
 default:search_index_o = 6'd32;
 endcase
end
endmodule
