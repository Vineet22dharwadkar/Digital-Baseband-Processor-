


//NEW
`timescale 1ns / 1ps

module input_preprocessor (
    input wire [7:0] i_data,
    input wire [7:0] q_data,
    input wire clk,
    input wire rst,
    input wire data_valid,
    
    output reg [7:0] I_data,
    output reg [7:0] Q_data,
    output reg data_out_valid
);

    localparam [7:0] MAX_VAL = 8'd127;
    localparam [7:0] MIN_VAL = 8'h80;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            I_data <= 8'sd0;
            Q_data <= 8'sd0;
            data_out_valid <= 1'b0;
        end else if (data_valid) begin
            // I-path clamping
            if ($signed(i_data) > $signed(MAX_VAL))
                I_data <= MAX_VAL;
            else if ($signed(i_data) < $signed(MIN_VAL))
                I_data <= MIN_VAL;
            else
                I_data <= i_data;
            
            // Q-path clamping
            if ($signed(q_data) > $signed(MAX_VAL))
                Q_data <= MAX_VAL;
            else if ($signed(q_data) < $signed(MIN_VAL))
                Q_data <= MIN_VAL;
            else
                Q_data <= q_data;
            
            data_out_valid <= 1'b1;
        end else begin
            data_out_valid <= 1'b0;
        end
    end
    
endmodule