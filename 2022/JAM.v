//------------------------------------------------------//
//- 2022 IC Design Contest                              //
//- Problem: Job Assignment Machine                     //
//- @author: Wei Chia Huang                             //
//- Last update: Jun 24 2023                            //
//------------------------------------------------------//
module JAM (
input CLK,
input RST,
output reg [2:0] W,
output reg [2:0] J,
input [6:0] Cost,
output reg [3:0] MatchCount,
output reg [9:0] MinCost,
output reg Valid );

integer i;

parameter  Catch        = 0,  
		   Find_pt      = 1,
           Find_min     = 2,
           Reverse_list = 3,
           Got_cost     = 4,
           Cal          = 5, 
           Output       = 6;

reg [2:0] arr[0:7]; 

reg sc;  //start catch
reg [2:0] w,j;
reg [6:0] Cost_mem[0:7][0:7];  //area bottleneck

reg [2:0] state;
reg [2:0] change_pt;
reg [2:0] min_pt;
reg [2:0] counter;
reg [9:0] total_cost;

reg first_signal;

always@(posedge CLK) begin
    if(RST)
        first_signal <= 1;
    
    else if(state == Got_cost)
        first_signal <= (first_signal == 1) ? 0 : first_signal;
end

always@(posedge CLK) begin
    if(RST) begin
        W <= 0; J <= 0; sc <= 0;
    end
    
    else if(state == Catch) begin
        sc <= (sc == 0) ? 1 : sc;
        
        if(J < 3'd7)
            J <= J + 1;
        
        else begin
            W <= W + 1; J <= 0;
        end
    end
end

always@(posedge CLK) begin
    if(RST) begin
        w <= 0; j <= 0; 
    end
    
    else if(state == Catch && sc == 1) begin
        Cost_mem[w][j] <= Cost;
        
		if(j < 3'd7)
            j <= j + 1;
        
        else begin
            w <= w + 1; j <= 0;
        end
    end
end

always@(posedge CLK) begin
    if(RST) begin
        change_pt <= 3'd6; min_pt <= 3'd7; counter <= 3'd7;
    end
    
    else if(state == Find_pt) begin
        if(arr[change_pt] > arr[change_pt+1] && change_pt != 0) begin
            change_pt <= change_pt - 1;
            min_pt <= min_pt - 1;
            counter <= counter - 1;
        end
    end

    else if(state == Find_min) begin
        if(counter != 7) begin
            if(arr[min_pt+1] > arr[change_pt] && arr[min_pt+1] < arr[min_pt])
            	min_pt <= min_pt + 1;
            counter <= counter + 1;
        end
    end
    
    else if(state == Cal) begin
        change_pt <= 3'd6; min_pt <= 3'd7; counter <= 3'd7;
    end
end

always@(posedge CLK) begin
	if(RST) begin	
		for(i = 0; i <= 7; i = i + 1)
            arr[i] <= i;
	end
    
    else if(state == Find_min) begin
        if(counter == 7) begin
            arr[change_pt] <= arr[min_pt];
            arr[min_pt] <= arr[change_pt];
        end
    end
    
    else if(state == Reverse_list) begin
        case(change_pt)
            0: begin
                for(i=1; i<=7; i=i+1)
                    arr[8-i] <= arr[0+i];
            end
            1: begin
                for(i=1; i<=6; i=i+1)
                    arr[8-i] <= arr[1+i];
            end
            2: begin
                for(i=1; i<=5; i=i+1)
                    arr[8-i] <= arr[2+i];
            end
            3: begin
                for(i=1; i<=4; i=i+1)
                    arr[8-i] <= arr[3+i];
            end
            4: begin
                for(i=1; i<=3; i=i+1)
                    arr[8-i] <= arr[4+i];
            end
            5: begin
                for(i=1; i<=2; i=i+1)
                    arr[8-i] <= arr[5+i];
            end
        endcase
    end
end

always@(posedge CLK) begin
    if(RST)
        total_cost <= 0;
    
    else if(state == Reverse_list)
        total_cost <= 0;
    
    else if(state == Got_cost) begin
        total_cost <= Cost_mem[0][arr[0]] + Cost_mem[1][arr[1]] + Cost_mem[2][arr[2]] + Cost_mem[3][arr[3]] 
                    + Cost_mem[4][arr[4]] + Cost_mem[5][arr[5]] + Cost_mem[6][arr[6]] + Cost_mem[7][arr[7]];
    end
end    

always@(posedge CLK) begin
    if(RST) begin
        MatchCount <= 0;
        MinCost <= 10'd1023;
    end
    
    else if(state == Cal) begin
        if(total_cost < MinCost) begin
            MinCost <= total_cost;
            MatchCount <= 4'd1;
        end
        
        else if(total_cost == MinCost)
            MatchCount <= MatchCount + 1;
    end
end

always@(posedge CLK) begin
    if(RST)
        Valid <= 0;
    
    else if(state == Output)
        Valid <= 1;
end

//FSM
always@(posedge CLK) begin
    if(RST) 
        state <= Catch;
    
    else if(state == Catch) begin
        if(w == 7 && j == 7)
            state <= Find_pt;
    end
    
    else if(state == Find_pt) begin
        if(first_signal == 1)
			state <= Got_cost;
		
        else if(arr[change_pt] < arr[change_pt+1])
            state <= Find_min;
        
        else if(arr[change_pt] > arr[change_pt+1] && change_pt == 0)
            state <= Output;
    end
    
    else if(state == Find_min) begin
        if(counter == 7)
            state <= Reverse_list;
    end
    
    else if(state == Reverse_list)
        state <= Got_cost;
    
    else if(state == Got_cost) 
        state <= Cal;
    
    else if(state == Cal)
        state <= Find_pt; 
end

endmodule
