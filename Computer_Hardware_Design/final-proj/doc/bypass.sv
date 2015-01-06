
always_comb begin


	for (int iter = 0 ; iter < 30 ; iter++) begin
	
		int i;
		
		if(iter + store_commit_entry_i + 1 > 31)  i = iter + store_commit_entry_i + 1 - 32;
		else i = iter + store_commit_entry_i + 1;
		
		//end of bypass
		if(i == tail-1) break;
	
		//search_valid1
		if(type_cam_r2_data == StoreWord) begin
			if (av_cam_data[i] && type_cam_data[i] == LoadWord) begin
				if (addr_cam_data[i] == addr_cam_r1_data)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LoadHalf) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] == addr_cam_r1_data + 16)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;				
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LoadByte) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] == addr_cam_r1_data + 8 ||
				    addr_cam_data[i] == addr_cam_r1_data + 16 || addr_cam_data[i] == addr_cam_r1_data + 24)
					search_valid1[i] = 1'b1;				
				else
					search_valid1[i] = 1'b0;				
			end	
			
			else search_valid1[i] = 1'b0;
		end
		
		else if(type_cam_r2_data == StoreHalf) begin
			if (av_cam_data[i] && type_cam_data[i] == LoadWord) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] + 16 == addr_cam_r1_data)
					search_valid1[i] = 1'b1;			
				else
					search_valid1[i] = 1'b0;				
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LoadHalf) begin
				if (addr_cam_data[i] == addr_cam_r1_data)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LoadByte) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] == addr_cam_r1_data + 8)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;				
			end			
		end
		
		else if(type_cam_r2_data == StoreByte) begin
			if (av_cam_data[i] && type_cam_data[i] == LoadWord) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] + 8 == addr_cam_r1_data ||
				    addr_cam_data[i] + 16 == addr_cam_r1_data || addr_cam_data[i] + 24 == addr_cam_r1_data )
					search_valid1[i] = 1'b1;					
				else
					search_valid1[i] = 1'b0;				
			end
		
			else if (av_cam_data[i] && type_cam_data[i] == LoadHalf) begin
				if (addr_cam_data[i] == addr_cam_r1_data || addr_cam_data[i] + 8 == addr_cam_r1_data)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;
			end
			
			else if (av_cam_data[i] && type_cam_data[i] == LoadByte) begin
				if (addr_cam_data[i] == addr_cam_r1_data)
					search_valid1[i] = 1'b1;
				else
					search_valid1[i] = 1'b0;				
			end				
		end
		
		else search_valid1[i] = 1'b0;
		
	end		
		
		
	priority casez (search_valid1)
		31'b???_????_????_????_????_????_????_???1: begin search = store_commit_entry_i + 1; end
		31'b???_????_????_????_????_????_????_??1?: begin search = store_commit_entry_i + 2; end
		31'b???_????_????_????_????_????_????_?1??: begin search = store_commit_entry_i + 3; end
		31'b???_????_????_????_????_????_????_1???: begin search = store_commit_entry_i + 4; end
		31'b???_????_????_????_????_????_???1_????: begin search = store_commit_entry_i + 5; end
		31'b???_????_????_????_????_????_??1?_????: begin search = store_commit_entry_i + 6; end
		31'b???_????_????_????_????_????_?1??_????: begin search = store_commit_entry_i + 7; end
		31'b???_????_????_????_????_????_1???_????: begin search = store_commit_entry_i + 8; end
		31'b???_????_????_????_????_???1_????_????: begin search = store_commit_entry_i + 9; end
		31'b???_????_????_????_????_??1?_????_????: begin search = store_commit_entry_i + 10; end
		31'b???_????_????_????_????_?1??_????_????: begin search = store_commit_entry_i + 11; end
		31'b???_????_????_????_????_1???_????_????: begin search = store_commit_entry_i + 12; end
		31'b???_????_????_????_???1_????_????_????: begin search = store_commit_entry_i + 13; end
		31'b???_????_????_????_??1?_????_????_????: begin search = store_commit_entry_i + 14; end
		31'b???_????_????_????_?1??_????_????_????: begin search = store_commit_entry_i + 15; end
		31'b???_????_????_????_1???_????_????_????: begin search = store_commit_entry_i + 16; end
		31'b???_????_????_???1_????_????_????_????: begin search = store_commit_entry_i + 17; end
		31'b???_????_????_??1?_????_????_????_????: begin search = store_commit_entry_i + 18; end
		31'b???_????_????_?1??_????_????_????_????: begin search = store_commit_entry_i + 19; end
		31'b???_????_????_1???_????_????_????_????: begin search = store_commit_entry_i + 20; end
		31'b???_????_???1_????_????_????_????_????: begin search = store_commit_entry_i + 21; end
		31'b???_????_??1?_????_????_????_????_????: begin search = store_commit_entry_i + 22; end
		31'b???_????_?1??_????_????_????_????_????: begin search = store_commit_entry_i + 23; end
		31'b???_????_1???_????_????_????_????_????: begin search = store_commit_entry_i + 24; end
		31'b???_???1_????_????_????_????_????_????: begin search = store_commit_entry_i + 25; end
		31'b???_??1?_????_????_????_????_????_????: begin search = store_commit_entry_i + 26; end
		31'b???_?1??_????_????_????_????_????_????: begin search = store_commit_entry_i + 27; end
		31'b???_1???_????_????_????_????_????_????: begin search = store_commit_entry_i + 28; end
		31'b??1_????_????_????_????_????_????_????: begin search = store_commit_entry_i + 29; end
		31'b?1?_????_????_????_????_????_????_????: begin search = store_commit_entry_i + 30; end
		31'b1??_????_????_????_????_????_????_????: begin search = store_commit_entry_i + 31; end
		endcase

		//search_valid_o
		if(|search_valid1) search_valid_o = 1;
		else search_valid_o = 0;		
		
		//search_index_o (bound)
		if(search > 31) search_index_o = search - 32;
		else search_index_o = search;
	
    if(search_valid_o) begin  
	
		//search_type_o
		if(type_cam_r2_data == StoreWord) begin
			if (type_cam_data[search_index_o] == LoadWord) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Word2Word;
				else
					search_type_o = None;
			end
		
			else if (type_cam_data[i] == LoadHalf) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = RWord2Half;
				else if(addr_cam_data[search_index_o] == addr_cam_r1_data + 16)
					search_type_o = LWord2Half;				
				else			
					search_type_o = None;
			end
			
			else if (type_cam_data[search_index_o] == LoadByte) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = FWord2Byte;
				else if(addr_cam_data[search_index_o] == addr_cam_r1_data + 8)
					search_type_o = SWord2Half;		
				else if(addr_cam_data[search_index_o] == addr_cam_r1_data + 16)
					search_type_o = TWord2Half;	
				else if(addr_cam_data[search_index_o] == addr_cam_r1_data + 24)
					search_type_o = FWord2Half;						
				else			
					search_type_o = None;
			end	
			
			else search_type_o = None;
		end
		
		else if(type_cam_r2_data == StoreHalf) begin
			if (type_cam_data[search_index_o] == LoadWord) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Half2RWord;
				else if(addr_cam_data[search_index_o] + 16 == addr_cam_r1_data)
					search_type_o = Half2LWord;				
				else
					search_type_o = None;			
			end
		
			else if (type_cam_data[search_index_o] == LoadHalf) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Half2Half;
				else
					search_type_o = None;
			end
			
			else if (type_cam_data[search_index_o] == LoadByte) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = LHalf2Byte;
				else if(addr_cam_data[search_index_o] == addr_cam_r1_data + 8)
					search_type_o = RHalf2Byte;	
				else
					search_type_o = None;		
			end			
		end
		
		else if(type_cam_r2_data == StoreByte) begin
			if (type_cam_data[search_index_o] == LoadWord) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Byte2FWord;
				else if(addr_cam_data[search_index_o] + 8 == addr_cam_r1_data)
					search_type_o = Byte2SWord;		
				else if(addr_cam_data[search_index_o] + 16 == addr_cam_r1_data)
					search_type_o = Byte2TWord;		
				else if(addr_cam_data[search_index_o] + 24 == addr_cam_r1_data)
					search_type_o = Byte2FWord;						
				else
					search_type_o = None;		
			end
		
			else if (type_cam_data[search_index_o] == LoadHalf) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Byte2RHalf;
				else
				else if (addr_cam_data[search_index_o] + 8 == addr_cam_r1_data)
					search_type_o = Byte2LHalf;
				else
					search_type_o = None;
			end
			
			else if (type_cam_data[search_index_o] == LoadByte) begin
				if (addr_cam_data[search_index_o] == addr_cam_r1_data)
					search_type_o = Byte2Byte;
				else
					search_type_o = None;		
			end				
		end
		
		else search_type_o = None;		
		
		

	
			case(search_type_o)
		
			Word2Word: begin //N = 0~3
				dataN_cam_r3_en = 1;
				dataN_cam_r3_index = store_commit_entry_i;
				dataN_cam_w3_en = 1;
				dataN_cam_w3_index = search_index_o;				
				dataN_cam_w3_data = dataN_cam_r3_data;
			end
			RWord2Half: begin //N = 0~1
				dataN_cam_r3_en = 1;
				dataN_cam_r3_index = store_commit_entry_i;
				dataN_cam_w3_en = 1;
				dataN_cam_w3_index = search_index_o;				
				dataN_cam_w3_data = dataN_cam_r3_data;
			end			
			LWord2Half: begin 
				data2_cam_r3_en = 1;
				data2_cam_r3_index = store_commit_entry_i;
				data3_cam_r3_en = 1;
				data3_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data2_cam_r3_data;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = search_index_o;				
				data1_cam_w3_data = data3_cam_r3_data;
			end						
			FWord2Byte: begin 
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data0_cam_r3_data;
			end	
			SWord2Byte: begin 
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data1_cam_r3_data;
			end			
			TWord2Byte: begin 
				data2_cam_r3_en = 1;
				data2_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data2_cam_r3_data;
			end		
			FWord2Byte: begin 
				data3_cam_r3_en = 1;
				data3_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data3_cam_r3_data;
			end		
			Half2RWord: begin //N = 0~1
				dataN_cam_r3_en = 1;
				dataN_cam_r3_index = store_commit_entry_i;
				dataN_cam_w3_en = 1;
				dataN_cam_w3_index = search_index_o;				
				dataN_cam_w3_data = dataN_cam_r3_data;
			end			
			Half2LWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data2_cam_w3_en = 1;
				data2_cam_w3_index = search_index_o;				
				data2_cam_w3_data = data0_cam_r3_data;
				data3_cam_w3_en = 1;
				data3_cam_w3_index = search_index_o;				
				data3_cam_w3_data = data1_cam_r3_data;
			end	
			Half2Half: begin //N = 0~1
				dataN_cam_r3_en = 1;
				dataN_cam_r3_index = store_commit_entry_i;
				dataN_cam_w3_en = 1;
				dataN_cam_w3_index = search_index_o;				
				dataN_cam_w3_data = dataN_cam_r3_data;
			end			
			LHalf2Byte: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data0_cam_r3_data;
			end			
			RHalf2Byte: begin
				data1_cam_r3_en = 1;
				data1_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data1_cam_r3_data;
			end		
			Byte2FWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data0_cam_r3_data;
			end		
			Byte2SWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = search_index_o;				
				data1_cam_w3_data = data0_cam_r3_data;
			end		
			Byte2TWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data2_cam_w3_en = 1;
				data2_cam_w3_index = search_index_o;				
				data2_cam_w3_data = data0_cam_r3_data;
			end		
			Byte2FWord: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data3_cam_w3_en = 1;
				data3_cam_w3_index = search_index_o;				
				data3_cam_w3_data = data0_cam_r3_data;
			end				
			Byte2RHalf: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data0_cam_r3_data;
			end	 
			Byte2LHalf: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data1_cam_w3_en = 1;
				data1_cam_w3_index = search_index_o;				
				data1_cam_w3_data = data0_cam_r3_data;
			end	 			
			Byte2Byte: begin
				data0_cam_r3_en = 1;
				data0_cam_r3_index = store_commit_entry_i;
				data0_cam_w3_en = 1;
				data0_cam_w3_index = search_index_o;				
				data0_cam_w3_data = data0_cam_r3_data;
			end	 	
			default: begin //N = 0~3
				dataN_cam_r3_en = 0;
				dataN_cam_r3_index = 5'b0;
				dataN_cam_w3_en = 0;
				dataN_cam_w3_index = 5'b0;				
				dataN_cam_w3_data = 8'b0;		
			end
		endcase
	
	
	
	//find second load
	for (int iter2 = 0 ; iter2 < 29 ; iter2++) begin
	
		int j;
		
		if(iter2 + search_valid_o + 1 > 31)  j = iter2 + search_valid_o + 1 - 32;
		else j = iter2 + search_valid_o + 1;
		
		//end of bypass
		if(j == tail-1) break;

		//search_valid2
		if(type_cam_r2_data == StoreWord) begin
			if (av_cam_data[j] && type_cam_data[j] == LoadWord) begin
				if (addr_cam_data[j] == addr_cam_r1_data)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LoadHalf) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] == addr_cam_r1_data + 16)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;				
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LoadByte) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] == addr_cam_r1_data + 8 ||
				    addr_cam_data[j] == addr_cam_r1_data + 16 || addr_cam_data[j] == addr_cam_r1_data + 24)
					search_valid2[j] = 1'b1;				
				else
					search_valid2[j] = 1'b0;				
			end	
			
			else search_valid2[j] = 1'b0;
		end
		
		else if(type_cam_r2_data == StoreHalf) begin
			if (av_cam_data[j] && type_cam_data[j] == LoadWord) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] + 16 == addr_cam_r1_data)
					search_valid2[j] = 1'b1;			
				else
					search_valid2[j] = 1'b0;				
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LoadHalf) begin
				if (addr_cam_data[j] == addr_cam_r1_data)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LoadByte) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] == addr_cam_r1_data + 8)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;				
			end			
		end
		
		else if(type_cam_r2_data == StoreByte) begin
			if (av_cam_data[j] && type_cam_data[j] == LoadWord) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] + 8 == addr_cam_r1_data ||
				    addr_cam_data[j] + 16 == addr_cam_r1_data || addr_cam_data[j] + 24 == addr_cam_r1_data )
					search_valid2[j] = 1'b1;					
				else
					search_valid2[j] = 1'b0;				
			end
		
			else if (av_cam_data[j] && type_cam_data[j] == LoadHalf) begin
				if (addr_cam_data[j] == addr_cam_r1_data || addr_cam_data[j] + 8 == addr_cam_r1_data)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;
			end
			
			else if (av_cam_data[j] && type_cam_data[j] == LoadByte) begin
				if (addr_cam_data[j] == addr_cam_r1_data)
					search_valid2[j] = 1'b1;
				else
					search_valid2[j] = 1'b0;				
			end				
		end
		
		else search_valid2[j] = 1'b0;
		
	end		
			
	priority casez (search_valid2)
		30'b??_????_????_????_????_????_????_???1: begin flush = search_valid_o + 1; end
		30'b??_????_????_????_????_????_????_??1?: begin flush = search_valid_o + 2; end
		30'b??_????_????_????_????_????_????_?1??: begin flush = search_valid_o + 3; end
		30'b??_????_????_????_????_????_????_1???: begin flush = search_valid_o + 4; end
		30'b??_????_????_????_????_????_???1_????: begin flush = search_valid_o + 5; end
		30'b??_????_????_????_????_????_??1?_????: begin flush = search_valid_o + 6; end
		30'b??_????_????_????_????_????_?1??_????: begin flush = search_valid_o + 7; end
		30'b??_????_????_????_????_????_1???_????: begin flush = search_valid_o + 8; end
		30'b??_????_????_????_????_???1_????_????: begin flush = search_valid_o + 9; end
		30'b??_????_????_????_????_??1?_????_????: begin flush = search_valid_o + 10; end
		30'b??_????_????_????_????_?1??_????_????: begin flush = search_valid_o + 11; end
		30'b??_????_????_????_????_1???_????_????: begin flush = search_valid_o + 12; end
		30'b??_????_????_????_???1_????_????_????: begin flush = search_valid_o + 13; end
		30'b??_????_????_????_??1?_????_????_????: begin flush = search_valid_o + 14; end
		30'b??_????_????_????_?1??_????_????_????: begin flush = search_valid_o + 15; end
		30'b??_????_????_????_1???_????_????_????: begin flush = search_valid_o + 16; end
		30'b??_????_????_???1_????_????_????_????: begin flush = search_valid_o + 17; end
		30'b??_????_????_??1?_????_????_????_????: begin flush = search_valid_o + 18; end
		30'b??_????_????_?1??_????_????_????_????: begin flush = search_valid_o + 19; end
		30'b??_????_????_1???_????_????_????_????: begin flush = search_valid_o + 20; end
		30'b??_????_???1_????_????_????_????_????: begin flush = search_valid_o + 21; end
		30'b??_????_??1?_????_????_????_????_????: begin flush = search_valid_o + 22; end
		30'b??_????_?1??_????_????_????_????_????: begin flush = search_valid_o + 23; end
		30'b??_????_1???_????_????_????_????_????: begin flush = search_valid_o + 24; end
		30'b??_???1_????_????_????_????_????_????: begin flush = search_valid_o + 25; end
		30'b??_??1?_????_????_????_????_????_????: begin flush = search_valid_o + 26; end
		30'b??_?1??_????_????_????_????_????_????: begin flush = search_valid_o + 27; end
		30'b??_1???_????_????_????_????_????_????: begin flush = search_valid_o + 28; end
		30'b?1_????_????_????_????_????_????_????: begin flush = search_valid_o + 29; end
		30'b1?_????_????_????_????_????_????_????: begin flush = search_valid_o + 30; end
		endcase		
			
		//flush_valid_o
		if(|search_valid2) flush_valid_o = 1;
		else flush_valid_o = 0;		
		
		//flush_index_o (bound)
		if(flush > 31) flush_index_o = flush - 32;
		else flush_entry_o = flush;
	end	
	
end