`timescale 1ns/100ps
module NFC(
    input clk,
    input rst,
    output done,
    inout [7:0] F_IO_A,
    output F_CLE_A,
    output F_ALE_A,
    output F_REN_A,
    output F_WEN_A,
    input F_RB_A,
    inout [7:0] F_IO_B,
    output F_CLE_B,
    output F_ALE_B,
    output F_REN_B,
    output F_WEN_B,
    input F_RB_B
);

// User registers
reg [10:0] count_init; // 0~32
reg [9:0] count_page; // 0~32
reg [9:0] count_page_2; // 0~32
reg [7:0] flash_mem_a; // Temp for F_IO
reg [7:0] flash_mem_b; // Temp for F_IO
reg f_wen_en;
reg f_ren_en;
reg [7:0] page_adrs;

reg f_io_a_en;
reg f_io_b_en;

reg done;
reg F_CLE_A;
reg F_ALE_A;
reg F_REN_A;
reg F_WEN_A;
reg F_CLE_B;
reg F_ALE_B;
reg F_REN_B;
reg F_WEN_B;

assign F_IO_A = (f_io_a_en) ? flash_mem_a : 8'bz; 
assign F_IO_B = (f_io_b_en) ? flash_mem_b : 8'bz; 

// Done
always @(posedge clk or posedge rst) begin
    if (rst)
        done <= 0;
    else if (count_init > 1051 && count_page == 512)
        done <= 1;
end

// Page address
always @(posedge clk or posedge rst) begin
    if (rst)
        page_adrs <= 0;
    else if (count_init > 8 && count_init < 11)
        page_adrs <= count_page_2;
    else if (count_init > 10 && count_init < 13) begin
        page_adrs[7:1] <= 7'd0;
        page_adrs[0] <= count_page_2[8];
    end 
end

// Flash memory A
always @(posedge clk or posedge rst) begin
    if (rst)
        flash_mem_a <= 8'hff;
    else if (count_init > 3 && count_init < 6)
        flash_mem_a <= 8'hff;
    else if (count_init > 5 && count_init < 8)
        flash_mem_a <= 0;
    else if (count_init > 7 && count_init < 10)
        flash_mem_a <= 0;
    else if (count_init > 9 && count_init < 14)
        flash_mem_a <= page_adrs;
end

// F_IO_A enable
always @(posedge clk or posedge rst) begin
    if (rst)
        f_io_a_en <= 0;
    else if (count_init > 3 && count_init < 14)
        f_io_a_en <= 1;
    else
        f_io_a_en <= 0;
end

// Count page
always @(posedge clk or posedge rst) begin
    if (rst)
        count_page <= 0;
    else if (count_init == 0)
        count_page <= count_page + 1'b1;
end

// Count page 2
always @(posedge clk or posedge rst) begin
    if (rst)
        count_page_2 <= 0;
    else 
        count_page_2 <= count_page - 1'b1;
end

// Count init
always @(posedge clk or posedge rst) begin
    if (rst)
        count_init <= 0;
    else if (count_init > 1052 && F_RB_B == 1)
        count_init <= 0;
    else  
        count_init <= count_init + 1'b1;
end

// F_WEN enable
always @(posedge clk or posedge rst) begin
    if (rst)
        f_wen_en <= 0;
    else if (count_init > 12)
        f_wen_en <= 0;
    else if (count_init == 3)
        f_wen_en <= 1;
    else if (count_init > 2)
        f_wen_en <= 1;
end

// F_WEN
always @(posedge clk or posedge rst) begin
    if (rst)
        F_WEN_A <= 0;
    else if (~f_wen_en)
        F_WEN_A <= 1;
    else if (f_wen_en)
        F_WEN_A <= ~F_WEN_A;
end

// F_CLE_A
always @(posedge clk or posedge rst) begin
    if (rst)
        F_CLE_A <= 0;
    else if (count_init > 3 && count_init < 8)
        F_CLE_A <= 1;
    else 
        F_CLE_A <= 0;
end

// F_ALE
always @(posedge clk or posedge rst) begin
    if (rst)
        F_ALE_A <= 1;
    else if (count_init > 7 && count_init < 14)
        F_ALE_A <= 1;
    else 
        F_ALE_A <= 0;
end

// F_REN enable
always @(posedge clk or posedge rst) begin
    if (rst)
        f_ren_en <= 0;
    else if (count_init > 1037)
        f_ren_en <= 0;
    else if (count_init > 13)
        f_ren_en <= 1;
end

// F_REN
always @(posedge clk or posedge rst) begin
    if (rst)
        F_REN_A <= 1;
    else if (~f_ren_en)
        F_REN_A <= 1;
    else if (f_ren_en)
        F_REN_A <= ~F_REN_A;
end

// F_CLE_B
always @(posedge clk or posedge rst) begin
    if (rst)
        F_CLE_B <= 0;
    else if (count_init == 1040 || count_init == 1041)
        F_CLE_B <= 1;
    else if (count_init > 1 && count_init < 8)
        F_CLE_B <= 1;
    else 
        F_CLE_B <= 0;
end

// F_ALE_B
always @(posedge clk or posedge rst) begin
    if (rst)
        F_ALE_B <= 1;
    else if (count_init > 7 && count_init < 14)
        F_ALE_B <= 1;
    else 
        F_ALE_B <= 0;
end

// F_REN_B
always @(posedge clk or posedge rst) begin
    if (rst)
        F_REN_B <= 1;
end

// F_WEN_B
always @(posedge clk or posedge rst) begin
    if (rst)
        F_WEN_B <= 1;
    else if (count_init > 1041)
        F_WEN_B <= 1;
    else if (count_init == 14 || count_init == 15)
        F_WEN_B <= 1;
    else if (count_init > 1)
        F_WEN_B <= ~F_WEN_B;
end

// Flash memory B
always @(posedge clk or posedge rst) begin
    if (rst)
        flash_mem_b <= 8'hff;
    else if (count_init > 1 && count_init < 4)
        flash_mem_b <= 8'hff;
    else if (count_init > 3 && count_init < 6)
        flash_mem_b <= 0;
    else if (count_init > 5 && count_init < 8)
        flash_mem_b <= 8'h80;
    else if (count_init > 7 && count_init < 10)
        flash_mem_b <= 0;
    else if (count_init > 9 && count_init < 14)
        flash_mem_b <= page_adrs;
    else if (count_init == 1040)
        flash_mem_b <= 8'h10;
    else if (count_init > 11) begin
        if (count_init % 2 == 0)
            flash_mem_b <= F_IO_A;
    end
end

// F_IO_B enable
always @(posedge clk or posedge rst) begin
    if (rst)
        f_io_b_en <= 0;
    else if (count_init == 14)
        f_io_b_en <= 0;
    else
        f_io_b_en <= 1;
end

endmodule
