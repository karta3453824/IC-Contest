module SME(clk, reset, chardata, isstring, ispattern, valid, match, match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output reg match;
output reg [4:0] match_index;
output reg valid;

parameter [1:0] LOAD   = 0,
                MATCH  = 1,
                OUTPUT = 2;

integer i;

reg [1:0] state;

reg [7:0] string_t[0:31];
reg [5:0] string_len;
reg [4:0] string_cnt;

reg str_change;

reg [7:0] pattern_t[0:7];
reg [5:0] pattern_len;
reg [4:0] pattern_cnt;
reg [7:0] pattern_t_temp[0:7];

reg [4:0] match_index_sp;  //match index for special case
reg sp;
reg [7:0] p0;
reg [2:0] idx;
reg [2:0] idx_s;

//str_change
always@(posedge clk or posedge reset) begin
    if(reset)
        str_change <= 0;
    
    else if(isstring)
        str_change <= 1;

    else
        str_change <= 0;
end

//reg for the case *:8'd42
always @(posedge clk or posedge reset) begin
    if(reset) begin
        sp <= 0; p0 <= 8'd0; idx <= 3'd0; idx_s <= 3'd0;
    end

    else if(pattern_t[pattern_cnt] == 8'd42) begin
        sp <= 1; p0 <= pattern_t[0];
        
        if(idx == 0) begin
            idx <= idx + 1; 
            idx_s <= pattern_cnt + 2;
        end

        else if(idx <= pattern_len-pattern_cnt-2) begin
            idx <= idx + 1; 
            idx_s <= idx_s + 1;
        end
    end
    
    else if(state == LOAD) begin
        sp <= 0; p0 <= 8'd0; idx <= 3'd0; idx_s <= 3'd0;
    end
end

//^:8'd94, $:8'd36, .:8'd46, *:8'd42, space:8'd32
always@(posedge clk or posedge reset) begin
    if(reset) begin
        match_index <= 5'd0; match_index_sp <= 5'd0;
        string_len  <= 6'd0; string_cnt     <= 5'd0;
        pattern_len <= 6'd0; pattern_cnt    <= 5'd0;

		for(i = 0; i < 8; i = i + 1) begin
        	pattern_t[i] <= 8'd0; 
			pattern_t_temp[i] <= 8'd0;
		end
    end    
    
    else if(isstring) begin
        if(str_change == 0) begin
            string_t[0] <= chardata;
            string_len <= 6'd1;
        end

        else begin
            string_t[string_len] <= chardata;
            string_len <= string_len + 6'd1;
        end
    end

    else if(ispattern) begin
        pattern_t[pattern_len] <= chardata;
        pattern_len <= pattern_len + 6'd1;

		if(pattern_len == 0)
			match_index <= 5'd0;
	end
    
    else if(state == MATCH && (pattern_cnt < pattern_len)) begin
        case(pattern_t[pattern_cnt])
            8'd94: begin
                if(match_index == 5'd0)
                    pattern_cnt <= pattern_cnt + 5'd1;
                
                else if(string_t[match_index] == 8'd32) begin
                    string_cnt  <= string_cnt  + 5'd1;
                    pattern_cnt <= pattern_cnt + 5'd1;
                end

                else begin
                    match_index <= match_index + 5'd1;
                    string_cnt  <= 5'd0;
                    pattern_cnt <= 5'd0;
                end
            end

            8'd36: begin
                if(string_t[match_index + string_cnt] == 8'd32 || ({1'b0, match_index} + pattern_len == string_len + 6'd1)) begin
                    string_cnt  <= string_cnt  + 5'd1;
                    pattern_cnt <= pattern_cnt + 5'd1;
                end  

                else begin
                    match_index <= match_index + 5'd1;
                    string_cnt  <= 5'd0;
                    pattern_cnt <= 5'd0;
                end
            end

            8'd42: begin
                if(idx == 0)
                    pattern_t_temp[idx] <= pattern_t[pattern_cnt+1];

                else if(idx <= pattern_len-pattern_cnt-2)
                    pattern_t_temp[idx] <= pattern_t[idx_s];
                
                else begin
                    for(i = 0; i < 8; i = i + 1)
                    	pattern_t[i] <= pattern_t_temp[i];
                    
					match_index_sp <= match_index;
                    match_index <= match_index + string_cnt;
                    pattern_len <= pattern_len - {1'b0, pattern_cnt} - 6'd1;
                    pattern_cnt <= 5'd0;
                    string_cnt  <= 5'd0;
                end
            end
            
            default: begin
                if(string_t[match_index + string_cnt] == pattern_t[pattern_cnt] || pattern_t[pattern_cnt] == 8'd46) begin
                    string_cnt  <= string_cnt  + 5'd1;
                    pattern_cnt <= pattern_cnt + 5'd1;
                end

                else begin
					if(match_index < 5'd31)
                    	match_index <= match_index + 5'd1;
                    string_cnt  <= 5'd0;
                    pattern_cnt <= 5'd0;
                end
           	end
        endcase
    end

    else if(state == OUTPUT) begin
		string_cnt  <= 5'd0;
        pattern_cnt <= 5'd0;
        pattern_len <= 6'd0;
		
		if(sp == 1) begin
            if(p0 == 8'd94 && match_index_sp != 5'd0)
                match_index <= match_index_sp + 5'd1;

            else
                match_index <= match_index_sp;
        end

        else begin
            if(pattern_t[0] == 8'd94 && match_index != 5'd0)
			    match_index <= match_index + 5'd1;
        end
	end
end

//FSM
always@(posedge clk or posedge reset) begin
    if(reset)
        state <= LOAD;
    
    else begin
        case(state)
            LOAD: begin
                if(isstring == 0 && ispattern == 0)
                    state <= MATCH;
            end

            MATCH: begin
                if(pattern_cnt == pattern_len)
                    state <= OUTPUT;
                
                else if(match_index == string_len -1)
                    state <= OUTPUT;
            end

            OUTPUT: begin
				if(valid)
                	state <= LOAD;
            end
        endcase
    end
end

//match
always@(posedge clk or posedge reset) begin
    if(reset)
        match <= 0;

    else if(pattern_cnt == pattern_len) 
        match <= 1;
    
    else if(state == LOAD)
        match <= 0;
end

//valid
always@(posedge clk or posedge reset) begin
    if(reset)
        valid <= 0;

    else if(state == OUTPUT)
        valid <= 1;
    
    else
        valid <= 0;
end
endmodule

