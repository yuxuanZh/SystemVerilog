
module ins_parse #(parameter INS_WIDTH = 32) (
input ins1_valid_i, ins2_valid_i,
input [INS_WIDTH-1:0] ins1_i, ins2_i,
output logic ls_type1_o,ls_type2_o,
output logic ls_valid1_o, ls_valid2_o
);

parameter SB = 17'bxxxxxxx_000_0100011,
		  SH = 17'bxxxxxxx_001_0100011,
		  SW = 17'bxxxxxxx_010_0100011,
		  LB = 17'bxxxxxxx_000_0000011,
		  LH = 17'bxxxxxxx_001_0000011,
		  LW = 17'bxxxxxxx_010_0000011;  

//parse instruction
always_comb begin
if(ins1_valid_i)
casex({ins1_i[31:25],ins1_i[14:12],ins1_i[6:0]})
LW: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b000;
	end

LH: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b001;
	end

LB: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b010;
	end

SW: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b100;
	end

SH: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b101;
	end

SB: begin
	ls_valid1_o = '1;
	ls_type1_o = 3'b110;
	end

default: begin
			ls_valid1_o = '0;
			ls_type1_o = 3'b111;
		 end
endcase
else ls_valid1_o = '0;

if(ins2_valid_i)
casex({ins2_i[31:25],ins2_i[14:12],ins2_i[6:0]})
LW: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b000;
	end

LH: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b001;
	end

LB: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b010;
	end

SW: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b100;
	end

SH: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b101;
	end

SB: begin
	ls_valid2_o = '1;
	ls_type2_o = 3'b110;
	end

default: begin
			ls_valid2_o = '0;
			ls_type2_o = 3'b111;
		 end
endcase
else ls_valid2_o = '0;
end

endmodule