
//currently using 

`timescale 1ns / 1ps

/*module CFIR(
    input wire clk,
    input wire reset,
    input wire signed [15:0] i_data_in,
    input wire signed [15:0] q_data_in,
    input wire valid_in,
    output reg signed [18:0] i_data_out,
    output reg signed [18:0] q_data_out,
    output reg valid_out
);

    localparam integer DATA_IN_W = 16;
    localparam integer COEFF_W = 10;
    localparam integer DATA_OUT_W = 19;
    localparam integer TAPS = 11;
    localparam integer MAC_W = 30;
    localparam integer SCALING_SHIFT = 11;

    reg signed [COEFF_W-1:0] h [0:TAPS-1];
    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS-1];
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS-1];

    reg signed [MAC_W-1:0] i_accum;
    reg signed [MAC_W-1:0] q_accum;

    integer i;

    initial begin
        h[0]=10'd10; h[1]=10'd15; h[2]=10'd25; h[3]=10'd40; h[4]=10'd65;
        h[5]=10'd70; h[6]=10'd65; h[7]=10'd40; h[8]=10'd25; h[9]=10'd15; h[10]=10'd10;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<TAPS; i=i+1) begin
                i_delay_line[i] <= 1'b0;
                q_delay_line[i] <= 1'b0;
            end
        end else if (valid_in) begin
            for (i=TAPS-1; i>0; i=i-1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
            i_delay_line[0] <= i_data_in;
            q_delay_line[0] <= q_data_in;
        end
    end

    always @* begin
        i_accum = {MAC_W{1'b0}};
        q_accum = {MAC_W{1'b0}};
        for (i=0; i<TAPS; i=i+1) begin
            i_accum = $signed(i_accum) + ($signed(h[i]) * $signed(i_delay_line[i]));
            q_accum = $signed(q_accum) + ($signed(h[i]) * $signed(q_delay_line[i]));
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i_data_out <= {DATA_OUT_W{1'b0}};
            q_data_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                i_data_out <= $signed(i_accum) >>> SCALING_SHIFT;
                q_data_out <= $signed(q_accum) >>> SCALING_SHIFT;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule*/




//==============================================================================================
// new one from the cloud 
module CFIR(
    input wire clk,
    input wire reset,
    input wire signed [15:0] i_data_in,
    input wire signed [15:0] q_data_in,
    input wire valid_in,
    output reg signed [18:0] i_data_out,
    output reg signed [18:0] q_data_out,
    output reg valid_out
);

    localparam integer DATA_IN_W = 16;
    localparam integer COEFF_W = 10;
    localparam integer DATA_OUT_W = 19;
    localparam integer TAPS = 11;
    localparam integer MAC_W = 30;
    localparam integer SCALING_SHIFT = 11;

    reg signed [COEFF_W-1:0] h [0:TAPS-1];
    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS-1];
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS-1];

    reg signed [MAC_W-1:0] i_accum;
    reg signed [MAC_W-1:0] q_accum;

    integer i;

    initial begin
        h[0]=10'd10; h[1]=10'd15; h[2]=10'd25; h[3]=10'd40; h[4]=10'd65;
        h[5]=10'd70; h[6]=10'd65; h[7]=10'd40; h[8]=10'd25; h[9]=10'd15; h[10]=10'd10;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<TAPS; i=i+1) begin
                i_delay_line[i] <= {DATA_IN_W{1'b0}};
                q_delay_line[i] <= {DATA_IN_W{1'b0}};
            end
        end else if (valid_in) begin
            for (i=TAPS-1; i>0; i=i-1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
            i_delay_line[0] <= i_data_in;
            q_delay_line[0] <= q_data_in;
        end
    end

    always @* begin
        i_accum = {MAC_W{1'b0}};
        q_accum = {MAC_W{1'b0}};
        for (i=0; i<TAPS; i=i+1) begin
            i_accum = $signed(i_accum) + ($signed(h[i]) * $signed(i_delay_line[i]));
            q_accum = $signed(q_accum) + ($signed(h[i]) * $signed(q_delay_line[i]));
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i_data_out <= {DATA_OUT_W{1'b0}};
            q_data_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            if (valid_in) begin
                i_data_out <= $signed(i_accum) >>> SCALING_SHIFT;
                q_data_out <= $signed(q_accum) >>> SCALING_SHIFT;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule


