

`timescale 1ns / 1ps

module DSP_Top (
    input wire clk,
    input wire reset,
    input wire signed [7:0] data_i_in_low,
    input wire signed [7:0] data_q_in_low,
    input wire valid_in_low,
    
    output wire signed [27:0] data_i_out_high,
    output wire signed [27:0] data_q_out_high,
    output wire valid_out_high
);

    wire signed [7:0] i_s1, q_s1;
    wire vld_s1;
    
    wire signed [15:0] i_s2, q_s2;
    wire vld_s2;

    wire signed [18:0] i_s3, q_s3;
    wire vld_s3;

    // FIXED: Now properly 21-bit (no truncation)
    wire signed [20:0] i_s4, q_s4;
    wire vld_s4;

    wire signed [23:0] i_s5, q_s5;
    wire vld_s5;
    
    wire signed [27:0] i_s6, q_s6;
    wire vld_s6;

    wire signed [27:0] i_s7, q_s7;
    wire vld_s7;

    input_preprocessor S1 (
        .clk(clk),
        .rst(reset),
        .i_data(data_i_in_low),
        .q_data(data_q_in_low),
        .data_valid(valid_in_low),
        .I_data(i_s1),
        .Q_data(q_s1),
        .data_out_valid(vld_s1)
    );

    cic_interpolator_x5 S2 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s1),
        .data_q_in(q_s1),
        .valid_in(vld_s1),
        .data_i_out(i_s2),
        .data_q_out(q_s2),
        .valid_out(vld_s2)
    );
    
    CFIR S3 (
        .clk(clk),
        .reset(reset),
        .i_data_in(i_s2),
        .q_data_in(q_s2),
        .valid_in(vld_s2),
        .i_data_out(i_s3),
        .q_data_out(q_s3),
        .valid_out(vld_s3)
    );

    // FIXED: Now outputs 21 bits directly
    CIC_Interpolator_Stage2 S4 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s3),
        .data_q_in(q_s3),
        .valid_in(vld_s3),
        .data_i_out(i_s4),    // 21-bit output
        .data_q_out(q_s4),    // 21-bit output
        .valid_out(vld_s4)
    );
    
    // FIXED: No more truncation - direct connection!
    PFIR_Filter S5 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s4),     // Direct 21-bit connection (no [20:0])
        .data_q_in(q_s4),     // Direct 21-bit connection (no [20:0])
        .valid_in(vld_s4),
        .data_i_out(i_s5),
        .data_q_out(q_s5),
        .valid_out(vld_s5)
    );

    Polyphase_FIR S6 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s5),
        .data_q_in(q_s5),
        .valid_in(vld_s5),
        .data_i_out(i_s6),
        .data_q_out(q_s6),
        .valid_out(vld_s6)
    );

    AntiImage_FIR S7 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s6),
        .data_q_in(q_s6),
        .valid_in(vld_s6),
        .data_i_out(i_s7),
        .data_q_out(q_s7),
        .valid_out(vld_s7)
    );

    NCO_Mixer S8 (
        .clk(clk),
        .reset(reset),
        .data_i_in(i_s7),
        .data_q_in(q_s7),
        .valid_in(vld_s7),
        .data_i_out(data_i_out_high),
        .data_q_out(data_q_out_high),
        .valid_out(valid_out_high)
    );

endmodule
