
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  reg [13:0] 	gray_addr;
output  reg       	gray_req;
input   gray_ready;
input [7:0] gray_data;
output  reg [13:0] 	lbp_addr;
output  reg	lbp_valid;
output  reg [8:0] 	lbp_data;
output  reg finish;
//====================================================================
reg [3:0] comp;
reg [13:0] store_index;
reg [7:0] next;
reg [7:0] now_num;
reg [7:0] total;
//////////////gray_req///////////////////
always @(posedge clk or posedge reset)begin
	if(reset) gray_req <= 1'b0;
	else if(gray_ready) gray_req <= 1'b1;
	else if(store_index == 16254 && comp == 10) gray_req <= 1'b0;
end
////////////////comp nine numbers//////////////////////
always @(posedge clk or posedge reset)begin
	if(reset) comp <= 4'd0;
 	else if(gray_req && comp == 10) comp <= 4'd0;
	else if(gray_ready) comp <= comp + 1;
end
///////////////next////////////////////
always @(posedge clk or posedge reset)begin
	if(reset) next <= 8'd0;
	else if(next ==125 && comp == 10) next <= 8'd0;
	else if(gray_req && comp == 10) next <= next + 1;
end
////////////store_index/////////////////
always @(posedge clk or posedge reset)begin
 	if(reset) store_index <= 14'd129;//first calculate

	else if(gray_req && next == 125 && comp == 10) store_index <= store_index + 3;

	else if(gray_req && comp == 10) store_index <= store_index + 1;


end
///////////now_num///////////////
always @ (posedge clk or posedge reset)
    if (reset) now_num <= 8'd0;
	else if (gray_req & comp == 4'd1) now_num <= gray_data;

//////////gray_addr//////////////////////////
always @(posedge clk or posedge reset)begin
	if(reset) gray_addr <= 14'd0;
	else if(gray_ready && comp == 0) gray_addr <= store_index;//129
	else if(gray_ready && comp == 1) gray_addr <= store_index-129;//0
	else if(gray_ready && comp == 2) gray_addr <= store_index-128;//1
	else if(gray_ready && comp == 3) gray_addr <= store_index-127;//2
	else if(gray_ready && comp == 4) gray_addr <= store_index-1;//128
	else if(gray_ready && comp == 5) gray_addr <= store_index+1;//130
	else if(gray_ready && comp == 6) gray_addr <= store_index+127;//256
	else if(gray_ready && comp == 7) gray_addr <= store_index+128;//257
	else if(gray_ready && comp == 8) gray_addr <= store_index+129;//258
end
/////////total//////////////////////////
always @(posedge clk or posedge reset)begin
	if(reset) total <= 8'd0;
	else if(gray_req && comp == 10) total <= 8'd0;
	else if(gray_req && comp == 2)begin
		if(now_num <= gray_data) total <= total + 1;
	end
	else if(gray_req && comp == 3)begin
		if(now_num <= gray_data) total <= total + 2;
	end
	else if(gray_req && comp == 4)begin
		if(now_num <= gray_data) total <= total + 4;
	end
	else if(gray_req && comp == 5)begin
		if(now_num <= gray_data) total <= total + 8;
	end
	else if(gray_req && comp == 6)begin
		if(now_num <= gray_data) total <= total + 16;
	end
	else if(gray_req && comp == 7)begin
		if(now_num <= gray_data) total <= total + 32;
	end
	else if(gray_req && comp == 8)begin
		if(now_num <= gray_data) total <= total + 64;
	end
	else if(gray_req && comp == 9)begin
		if(now_num <= gray_data) total <= total + 128;
	end
end
////////////lbp_valid/////////////
always @(posedge clk or posedge reset)begin
	if(reset) lbp_valid <= 1'b0;
	else if(gray_req && comp == 9) lbp_valid <= 1'b1;
	else if(lbp_valid) lbp_valid <= 1'b0;
end
///////////////lbp_addr/////////////
always @(posedge clk or posedge reset)begin
	if(reset) lbp_addr <= 14'd0;
	else if(gray_req && comp == 9) lbp_addr <= store_index;
end
///////////////lbp_data/////////////
always @(posedge clk or posedge reset)begin
	if(reset) lbp_data <= 8'd0;
	else if(gray_req && comp == 9)begin
		if(now_num <= gray_data) lbp_data <= total+ 128;
		else lbp_data <= total;
	end
end
///////////////finish/////////////
always @(posedge clk or posedge reset)begin
	if(reset) finish <= 1'b0;
	else if(store_index == 16254 && comp == 10) finish <= 1'b1;	
end

endmodule



