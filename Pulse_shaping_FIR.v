

`timescale 1ns / 1ps

module PFIR_Filter (
    input wire clk,
    input wire reset,
    input wire signed [20:0] data_i_in,
    input wire signed [20:0] data_q_in,
    input wire valid_in,
    output reg signed [23:0] data_i_out,
    output reg signed [23:0] data_q_out,
    output reg valid_out
);

    localparam TAPS = 32;
    localparam UNIQUE_TAPS = TAPS/2;
    localparam DATA_IN_W = 21;
    localparam COEFF_W = 14;
    localparam DATA_OUT_W = 24;
    localparam MAC_W = DATA_IN_W + COEFF_W + 5;
    localparam SCALE_SHIFT = COEFF_W - 1;

    reg signed [COEFF_W-1:0] h [0:UNIQUE_TAPS-1];

    initial begin
        h[0] = 14'sh3FEC; h[1] = 14'sh3FF4; h[2] = 14'sd2; h[3] = 14'sd19;
        h[4] = 14'sd39; h[5] = 14'sd63; h[6] = 14'sd92; h[7] = 14'sd125;
        h[8] = 14'sd162; h[9] = 14'sd202; h[10] = 14'sd246; h[11] = 14'sd293;
        h[12] = 14'sd342; h[13] = 14'sd394; h[14] = 14'sd446; h[15] = 14'sd500;
    end

    reg signed [DATA_IN_W-1:0] i_delay [0:TAPS-1];
    reg signed [DATA_IN_W-1:0] q_delay [0:TAPS-1];

    integer j;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (j=0; j<TAPS; j=j+1) begin
                i_delay[j] <= {DATA_IN_W{1'b0}};
                q_delay[j] <= {DATA_IN_W{1'b0}};
            end
        end else if (valid_in) begin
            for (j=TAPS-1; j>0; j=j-1) begin
                i_delay[j] <= i_delay[j-1];
                q_delay[j] <= q_delay[j-1];
            end
            i_delay[0] <= data_i_in;
            q_delay[0] <= data_q_in;
        end
    end

    wire signed [MAC_W-1:0] i_sum_comb;
    wire signed [MAC_W-1:0] q_sum_comb;

    assign i_sum_comb =
        $signed(h[0]) * ($signed(i_delay[0]) + $signed(i_delay[31])) +
        $signed(h[1]) * ($signed(i_delay[1]) + $signed(i_delay[30])) +
        $signed(h[2]) * ($signed(i_delay[2]) + $signed(i_delay[29])) +
        $signed(h[3]) * ($signed(i_delay[3]) + $signed(i_delay[28])) +
        $signed(h[4]) * ($signed(i_delay[4]) + $signed(i_delay[27])) +
        $signed(h[5]) * ($signed(i_delay[5]) + $signed(i_delay[26])) +
        $signed(h[6]) * ($signed(i_delay[6]) + $signed(i_delay[25])) +
        $signed(h[7]) * ($signed(i_delay[7]) + $signed(i_delay[24])) +
        $signed(h[8]) * ($signed(i_delay[8]) + $signed(i_delay[23])) +
        $signed(h[9]) * ($signed(i_delay[9]) + $signed(i_delay[22])) +
        $signed(h[10]) * ($signed(i_delay[10]) + $signed(i_delay[21])) +
        $signed(h[11]) * ($signed(i_delay[11]) + $signed(i_delay[20])) +
        $signed(h[12]) * ($signed(i_delay[12]) + $signed(i_delay[19])) +
        $signed(h[13]) * ($signed(i_delay[13]) + $signed(i_delay[18])) +
        $signed(h[14]) * ($signed(i_delay[14]) + $signed(i_delay[17])) +
        $signed(h[15]) * ($signed(i_delay[15]) + $signed(i_delay[16]));

    assign q_sum_comb =
        $signed(h[0]) * ($signed(q_delay[0]) + $signed(q_delay[31])) +
        $signed(h[1]) * ($signed(q_delay[1]) + $signed(q_delay[30])) +
        $signed(h[2]) * ($signed(q_delay[2]) + $signed(q_delay[29])) +
        $signed(h[3]) * ($signed(q_delay[3]) + $signed(q_delay[28])) +
        $signed(h[4]) * ($signed(q_delay[4]) + $signed(q_delay[27])) +
        $signed(h[5]) * ($signed(q_delay[5]) + $signed(q_delay[26])) +
        $signed(h[6]) * ($signed(q_delay[6]) + $signed(q_delay[25])) +
        $signed(h[7]) * ($signed(q_delay[7]) + $signed(q_delay[24])) +
        $signed(h[8]) * ($signed(q_delay[8]) + $signed(q_delay[23])) +
        $signed(h[9]) * ($signed(q_delay[9]) + $signed(q_delay[22])) +
        $signed(h[10]) * ($signed(q_delay[10]) + $signed(q_delay[21])) +
        $signed(h[11]) * ($signed(q_delay[11]) + $signed(q_delay[20])) +
        $signed(h[12]) * ($signed(q_delay[12]) + $signed(q_delay[19])) +
        $signed(h[13]) * ($signed(q_delay[13]) + $signed(q_delay[18])) +
        $signed(h[14]) * ($signed(q_delay[14]) + $signed(q_delay[17])) +
        $signed(h[15]) * ($signed(q_delay[15]) + $signed(q_delay[16]));

    reg signed [MAC_W-1:0] i_mac_reg, q_mac_reg;
    reg vld_pipe1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i_mac_reg <= {MAC_W{1'b0}};
            q_mac_reg <= {MAC_W{1'b0}};
            vld_pipe1 <= 1'b0;
            data_i_out <= {DATA_OUT_W{1'b0}};
            data_q_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                i_mac_reg <= i_sum_comb;
                q_mac_reg <= q_sum_comb;
            end
            vld_pipe1 <= valid_in;

            if (vld_pipe1) begin
                data_i_out <= $signed(i_mac_reg >>> SCALE_SHIFT);
                data_q_out <= $signed(q_mac_reg >>> SCALE_SHIFT);
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule
