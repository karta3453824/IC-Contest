//------------------------------------------------------//
//- 2023 IC Design Contest                              //
//- Problem: Laser Treatment                            //
//- @author: Wei Chia Huang                             //
//- Last update: Jun 1 2023                             //
//------------------------------------------------------//
module LASER (
    input CLK,
    input RST,
    input [3:0] X,
    input [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
);

integer i, j;
parameter INPUT  = 0,
          WAIT   = 1, 
          FIND   = 2,
          CHECK  = 3,
          OUTPUT = 4;

reg [2:0] state;

reg [7:0] counter;
reg [2:0] counter_2;  //for four times calculate + 2 cycles delay calculation

reg [3:0] x_cor[0:39], y_cor[0:39];  //store the points in x-y plane
reg [9:0] p1_list[0:3], p2_list[0:3];  //store which dots are chosen by circle_1 and circle_2

reg [3:0] x, y, x1, y1, x2, y2, x_old, y_old;
reg [5:0] p1, p2, p, true_p1, true_p;  //store how many dots are covered
reg [9:0] p_arr[0:3];

reg [3:0] abs_x[0:9], abs_y[0:9];

reg [9:0] quarter_list[0:3];  //store which points are covered by circle(use to avoid recalculating the points which are covered by both two circles)

//FSM
always@(posedge CLK) begin
    if(RST)
        state <= INPUT;
    
    else begin
        case(state)
            INPUT: state <= (counter == 39)? WAIT : INPUT;

            WAIT: state <= (counter_2 == 6)? FIND : WAIT;

            FIND: state <= (counter == 192)? CHECK : WAIT;

            CHECK: state <= (x1 == x_old && y1 == y_old)? OUTPUT : WAIT;  //check if result is converged
        
            OUTPUT: state <= INPUT;
        
            default: state <= INPUT;
        endcase
    end
end

//store input data
always@(posedge CLK) begin
    if(state == INPUT) begin
        x_cor[counter] <= X;
        y_cor[counter] <= Y;
    end

    else if(state == WAIT && (counter_2 <= 3)) begin
        for(j = 0; j < 10; j = j + 1) begin
            x_cor[j]    <= x_cor[j+10];    y_cor[j]    <= y_cor[j+10];
            x_cor[j+10] <= x_cor[j+20];    y_cor[j+10] <= y_cor[j+20];
            x_cor[j+20] <= x_cor[j+30];    y_cor[j+20] <= y_cor[j+30];
            x_cor[j+30] <=    x_cor[j];    y_cor[j+30] <=    y_cor[j];
        end
    end
end

//calculate how manys points are covered in a certain circle
always@(posedge CLK) begin
    if(state == WAIT && (counter_2 <= 3)) begin
        for(i = 0; i < 10; i = i + 1) begin
            abs_x[i] <= (x >= x_cor[i])? x - x_cor[i] : x_cor[i] - x;
            abs_y[i] <= (y >= y_cor[i])? y - y_cor[i] : y_cor[i] - y;
        end
    end
end

always@(posedge CLK) begin
    if((counter_2 >= 1) && (counter_2 <= 4)) begin
        for(i = 0; i < 10; i = i + 1)
            quarter_list[counter_2 - 1][i] <= (abs_x[i] + abs_y[i] <= 4) || (abs_x[i] == 3 && abs_y[i] == 2) || (abs_x[i] == 2 && abs_y[i] == 3);
    end    
end

always@(posedge CLK) begin
    if((counter_2 >= 2) && (counter_2 <= 5)) begin
        for(i = 0; i < 10; i = i + 1)
            p_arr[counter_2 - 2][i] <= (p2_list[counter_2 - 2][i])? 0 : quarter_list[counter_2 - 2][i];
    end
end

always@(posedge CLK) begin
    if((counter_2 >= 3) && (counter_2 <= 6)) begin
        p <= p_arr[counter_2 - 3][0] + p_arr[counter_2 - 3][1] + p_arr[counter_2 - 3][2] + p_arr[counter_2 - 3][3] + 
             p_arr[counter_2 - 3][4] + p_arr[counter_2 - 3][5] + p_arr[counter_2 - 3][6] + p_arr[counter_2 - 3][7] +
             p_arr[counter_2 - 3][8] + p_arr[counter_2 - 3][9] + p;
    end

    else if(counter_2 == 0)
        p <= 0;
end

always@(posedge CLK) begin
    if((counter_2 >= 2) && (counter_2 <= 5)) begin
        true_p1 <= quarter_list[counter_2 - 2][0] + quarter_list[counter_2 - 2][1] + quarter_list[counter_2 - 2][2] + quarter_list[counter_2 - 2][3] +
                   quarter_list[counter_2 - 2][4] + quarter_list[counter_2 - 2][5] + quarter_list[counter_2 - 2][6] + quarter_list[counter_2 - 2][7] +
                   quarter_list[counter_2 - 2][8] + quarter_list[counter_2 - 2][9] + true_p1;
    end
    
    else if(counter_2 == 0)
        true_p1 <= 0;
end

//x1, y1, x2, y2, p1, p2
//xy: coordinate
//p: how many dots are covered
always@(posedge CLK) begin
    case(state)
        INPUT: begin
            x1 <= 0; y1 <= 0; p1 <= 0;
            x2 <= 0; y2 <= 0; p2 <= 0;
            x_old <= 0; y_old <= 0;
			
            for(i = 0; i < 4; i = i + 1) begin
                p1_list[i] <= 0; 
                p2_list[i] <= 0;
            end
		end
        
        FIND: begin
            if(p >= p1) begin
                x1 <= x; y1 <= y; p1 <= p; true_p <= true_p1;
                
				for(i = 0; i < 4; i = i + 1)
                	p1_list[i] <= quarter_list[i];
            end
        end
        
        CHECK: begin  //fixed this circle and turn to scan another circle, check if result is converged
            for(i = 0; i < 4; i = i + 1)
                p2_list[i] <= p1_list[i];
            
			x1 <= 0; y1 <= 0; p1 <= 0;
            x2 <= x1; y2 <= y1; p2 <= true_p;  //we need true p that do not care about whether it covered by another circle
            x_old <= x2; y_old <= y2;
        end
        
        OUTPUT: begin
            x1 <= 0; y1 <= 0; p1 <= 0;
            x2 <= 0; y2 <= 0; p2 <= 0;
        end

        default:
            ;
    endcase
end

//counter_2
always@(posedge CLK)
    counter_2 <= (state == WAIT) ? counter_2 + 1 : 0;

//scanning x, y coordinate
always@(*) begin
    x = counter[3:0]; 
    y = counter[7:4];
end

//counter
always@(posedge CLK) begin
    if(RST)
        counter <= 0;
    
    else begin
        case(state)
            INPUT: begin
				if(DONE == 0)
					counter <= (counter == 39)? 0 : counter + 1;
            end
            
			FIND: begin  //special xy scanning path
                if(counter[3:0] == 12)
                    counter <= (y == 0)? counter + 32: (y == 2)? counter + 46 : (y == 7)? counter + 39 : counter + 4;
                
                else 
                    counter <= (counter[3:0] == 0 || counter[3:0] == 6)? counter + 3 : counter + 1;
            end

            WAIT:
		    	;
			
            default:
                counter <= 0;
        endcase
    end
end

//C1X, C1Y, C2X, C2Y
always@(posedge CLK) begin
    if(RST) begin
        C1X <= 0; C1Y <= 0;
        C2X <= 0; C2Y <= 0;
    end
    
    else begin
        if(state == CHECK) begin
            C1X <= x1; C1Y <= y1;
            C2X <= x2; C2Y <= y2;
        end
    end
end

//DONE
always@(*) begin
    DONE <= (state == OUTPUT);
end

endmodule
