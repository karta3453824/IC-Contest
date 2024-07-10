module huffman(
    input clk,
    input reset,
    input gray_valid,
    input [7:0] gray_data,
    output reg CNT_valid,
    output reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    output reg code_valid,
    output reg [7:0] HC1, HC2, HC3, HC4, HC5, HC6,
    output reg [7:0] M1, M2, M3, M4, M5, M6
);

// State switch
reg [3:0] NOW, NS;
parameter IDLE = 4'd0;
parameter REC_CNTi = 4'd1;
parameter OUT_CNTi = 4'd2;
parameter FINDMIN = 4'd3;
parameter MERGECNTi = 4'd4;
parameter HC_AND_MASK = 4'd5;
parameter OUT_HCi_Mi = 4'd6;

// CNTi
reg reset_temp, gray_valid_temp;
reg [7:0] gray_data_temp;
reg [7:0] CNTi[1:6];
reg [3:0] i, j;

// FINDMIN
reg [7:0] symbol[1:6];
reg [7:0] MIN1;
reg [7:0] MIN2;
reg [3:0] MIN1_IDX;
reg [3:0] MIN2_IDX;
reg [7:0] SYMBOL_MIN1;
reg [7:0] SYMBOL_MIN2;
reg [3:0] MIN_COUNT, limit, C_COUNT;

// HC_CODE
reg [7:0] HC_CODE[6:1];
reg [2:0] HC_COUNT[6:1];
reg [7:0] MASK[1:6];

always @(posedge clk) begin
    reset_temp <= reset;
end

always @(posedge clk) begin
    if (reset_temp)
        gray_valid_temp <= 0;
    else
        gray_valid_temp <= gray_valid;
end

always @(posedge clk) begin
    if (reset_temp)
        gray_data_temp <= 0;
    else
        gray_data_temp <= gray_data;
end

// State switch
always @(posedge clk) begin
    if (reset)
        NOW <= IDLE;
    else
        NOW <= NS;
end

always @(*) begin
    case (NOW)
        IDLE: begin
            if (gray_valid_temp)
                NS = REC_CNTi;
            else
                NS = IDLE;
        end

        REC_CNTi: begin
            if (gray_valid_temp == 0)
                NS = OUT_CNTi;
            else
                NS = REC_CNTi;
        end

        OUT_CNTi: begin
            NS = FINDMIN;
        end

        FINDMIN: begin
            if (MIN_COUNT == limit)
                NS = MERGECNTi;
            else
                NS = FINDMIN;
        end

        MERGECNTi: begin
            NS = HC_AND_MASK;
        end

        HC_AND_MASK: begin
            if (C_COUNT == 3'd5)
                NS = OUT_HCi_Mi;
            else
                NS = FINDMIN;
        end

        OUT_HCi_Mi: begin

        end

        default: NS = IDLE;
    endcase
end

// CNTi
always @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < 7; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                if (i == j)
                    symbol[i][j] <= 1;
                else
                    symbol[i][j] <= 0;
            end
        end
        for (i = 1; i < 7; i = i + 1) begin
            CNTi[i] <= 8'd0;
        end
    end else if (NS == REC_CNTi) begin
        CNTi[gray_data_temp] <= CNTi[gray_data_temp] + 8'd1;
    end else if (NOW == MERGECNTi) begin
        if (MIN1_IDX < MIN2_IDX) begin
            CNTi[MIN1_IDX] <= CNTi[MIN1_IDX] + CNTi[MIN2_IDX];
            symbol[MIN1_IDX] <= symbol[MIN1_IDX] + symbol[MIN2_IDX];
            symbol[MIN1_IDX][7] <= 1;
            for (i = 1; i < 6; i = i + 1) begin
                if (i >= MIN2_IDX) begin
                    CNTi[i] <= CNTi[i + 1];
                    symbol[i] <= symbol[i + 1];
                end
            end
        end else begin
            CNTi[MIN2_IDX] <= CNTi[MIN1_IDX] + CNTi[MIN2_IDX];
            symbol[MIN2_IDX] <= symbol[MIN1_IDX] + symbol[MIN2_IDX];
            symbol[MIN2_IDX][7] <= 1;
            for (i = 1; i < 6; i = i + 1) begin
                if (i >= MIN1_IDX) begin
                    CNTi[i] <= CNTi[i + 1];
                    symbol[i] <= symbol[i + 1];
                end
            end
        end
    end
end

always @(posedge clk) begin
    if (reset)
        CNT_valid <= 0;
    else if (NOW == OUT_CNTi)
        CNT_valid <= 1;
    else if (NOW == FINDMIN)
        CNT_valid <= 0;
end

// CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
always @(posedge clk) begin
    if (NS == OUT_CNTi) begin
        CNT1 <= CNTi[1];
        CNT2 <= CNTi[2];
        CNT3 <= CNTi[3];
        CNT4 <= CNTi[4];
        CNT5 <= CNTi[5];
        CNT6 <= CNTi[6];
    end
end

// MERGECNTi and FINDMIN
always @(posedge clk) begin
    if (reset) begin
        MIN_COUNT <= 4'd1;
        limit <= 4'd6;
    end else if (NOW == MERGECNTi && NS == HC_AND_MASK) begin
        MIN_COUNT <= 4'd1;
        limit <= limit - 4'd1;
    end else if (NOW == FINDMIN) begin
        MIN_COUNT <= MIN_COUNT + 4'd1;
    end
end

// FINDMIN
always @(posedge clk) begin
    if (reset) begin
        MIN1_IDX <= 4'd0;
        SYMBOL_MIN1 <= 8'd0;
        MIN1 <= 8'd100;
        MIN2_IDX <= 4'd0;
        SYMBOL_MIN2 <= 8'd0;
        MIN2 <= 8'd100;
    end else if (NOW == HC_AND_MASK && NS == FINDMIN) begin
        MIN1_IDX <= 4'd0;
        SYMBOL_MIN1 <= 8'd0;
        MIN1 <= 8'd100;
        MIN2_IDX <= 4'd0;
        SYMBOL_MIN2 <= 8'd0;
        MIN2 <= 8'd100;
    end else if (NOW == FINDMIN) begin
        if (CNTi[MIN_COUNT] < MIN1) begin
            MIN1 <= CNTi[MIN_COUNT];
            SYMBOL_MIN1 <= symbol[MIN_COUNT];
            MIN1_IDX <= MIN_COUNT;
            MIN2 <= MIN1;
            SYMBOL_MIN2 <= SYMBOL_MIN1;
            MIN2_IDX <= MIN1_IDX;
        end else if (CNTi[MIN_COUNT] == MIN1) begin
            if (symbol[MIN_COUNT] > SYMBOL_MIN1) begin
                MIN1 <= CNTi[MIN_COUNT];
                SYMBOL_MIN1 <= symbol[MIN_COUNT];
                MIN1_IDX <= MIN_COUNT;
                MIN2 <= MIN1;
                SYMBOL_MIN2 <= SYMBOL_MIN1;
                MIN2_IDX <= MIN1_IDX;
            end else if (symbol[MIN_COUNT] > SYMBOL_MIN2) begin
                MIN2 <= CNTi[MIN_COUNT];
                SYMBOL_MIN2 <= symbol[MIN_COUNT];
                MIN2_IDX <= MIN_COUNT;
            end
        end else if (CNTi[MIN_COUNT] < MIN2) begin
            MIN2 <= CNTi[MIN_COUNT];
            SYMBOL_MIN2 <= symbol[MIN_COUNT];
            MIN2_IDX <= MIN_COUNT;
        end else if (CNTi[MIN_COUNT] == MIN2) begin
            if (symbol[MIN_COUNT] > SYMBOL_MIN2) begin
                MIN2 <= CNTi[MIN_COUNT];
                SYMBOL_MIN2 <= symbol[MIN_COUNT];
                MIN2_IDX <= MIN_COUNT;
            end
        end
    end
end

// HC_count
always @(posedge clk) begin
    if (reset)
        C_COUNT <= 0;
    else if (NOW == MERGECNTi && NS == HC_AND_MASK)
        C_COUNT <= C_COUNT + 4'd1;
end

always @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < 7; i = i + 1) begin
            HC_COUNT[i] <= 3'd0;
        end
    end else if (NOW == HC_AND_MASK) begin
        for (i = 1; i < 7; i = i + 1) begin
            if (SYMBOL_MIN1[i] == 1 || SYMBOL_MIN2[i] == 1) begin
                HC_COUNT[i] <= HC_COUNT[i] + 3'd1;
            end
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < 7; i = i + 1) begin
            HC_CODE[i] <= 8'd0;
        end
    end else if (NOW == HC_AND_MASK) begin
        for (i = 1; i < 7; i = i + 1) begin
            if (SYMBOL_MIN1[i] == 1) begin
                if (HC_COUNT[i] == 0)
                    HC_CODE[i][0] <= 1;
                else if (HC_COUNT[i] == 1)
                    HC_CODE[i][1] <= 1;
                else if (HC_COUNT[i] == 2)
                    HC_CODE[i][2] <= 1;
                else if (HC_COUNT[i] == 3)
                    HC_CODE[i][3] <= 1;
                else if (HC_COUNT[i] == 4)
                    HC_CODE[i][4] <= 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < 7; i = i + 1) begin
            MASK[i] <= 8'd0;
        end
    end else if (NOW == HC_AND_MASK) begin
        for (i = 1; i < 7; i = i + 1) begin
            if (SYMBOL_MIN1[i] == 1 || SYMBOL_MIN2[i] == 1) begin
                if (HC_COUNT[i] == 0)
                    MASK[i][0] <= 1;
                else if (HC_COUNT[i] == 1)
                    MASK[i][1] <= 1;
                else if (HC_COUNT[i] == 2)
                    MASK[i][2] <= 1;
                else if (HC_COUNT[i] == 3)
                    MASK[i][3] <= 1;
                else if (HC_COUNT[i] == 4)
                    MASK[i][4] <= 1;
            end
        end
    end
end

always @(posedge clk) begin
    if (NOW == OUT_HCi_Mi)
        code_valid <= 1;
    else
        code_valid <= 0;
end

always @(posedge clk) begin
    if (NOW == OUT_HCi_Mi) begin
        HC1 <= HC_CODE[1];
        HC2 <= HC_CODE[2];
        HC3 <= HC_CODE[3];
        HC4 <= HC_CODE[4];
        HC5 <= HC_CODE[5];
        HC6 <= HC_CODE[6];
        M1 <= MASK[1];
        M2 <= MASK[2];
        M3 <= MASK[3];
        M4 <= MASK[4];
        M5 <= MASK[5];
        M6 <= MASK[6];
    end
end

endmodule
