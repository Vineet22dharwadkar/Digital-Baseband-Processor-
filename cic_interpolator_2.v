

`timescale 1ns / 1ps 

module CIC_Interpolator_Stage2(
    input clk,
    input reset,
    input signed [18:0] data_i_in,
    input signed [18:0] data_q_in,
    input valid_in,
    output reg signed [20:0] data_i_out,  // 21-bit output
    output reg signed [20:0] data_q_out,  // 21-bit output
    output reg valid_out
);

    localparam R = 5;
    localparam N = 3;
    localparam INPUT_W = 19;
    localparam INTERNAL_W = 28;  // Internal processing width
    localparam OUTPUT_W = 21;    // Output width (to PFIR)
    localparam SHIFT_W = 7;      // CIC gain compensation

    reg signed [INTERNAL_W-1:0] i_int_reg [N-1:0];
    reg signed [INTERNAL_W-1:0] q_int_reg [N-1:0];

    reg signed [INTERNAL_W-1:0] i_comb_in;
    reg signed [INTERNAL_W-1:0] q_comb_in;

    reg signed [INTERNAL_W-1:0] i_delay_line [R-1:0];
    reg signed [INTERNAL_W-1:0] q_delay_line [R-1:0];

    reg signed [INTERNAL_W-1:0] i_comb_out [N-1:0];
    reg signed [INTERNAL_W-1:0] q_comb_out [N-1:0];

    reg [2:0] rate_counter;
    wire high_rate_tick;

    // Temporary registers for shifted output (fixes syntax issue)
    reg signed [INTERNAL_W-1:0] i_shifted;
    reg signed [INTERNAL_W-1:0] q_shifted;

    integer i;

    assign high_rate_tick = (rate_counter > 3'd0);

    // ============================================================
    // Integrators (internal 28-bit processing)
    // ============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < N; i = i + 1) begin
                i_int_reg[i] <= {INTERNAL_W{1'b0}};
                q_int_reg[i] <= {INTERNAL_W{1'b0}};
            end
            i_comb_in <= {INTERNAL_W{1'b0}};
            q_comb_in <= {INTERNAL_W{1'b0}};
        end else if (valid_in) begin
            i_comb_in <= {{INTERNAL_W-INPUT_W{data_i_in[INPUT_W-1]}}, data_i_in};
            q_comb_in <= {{INTERNAL_W-INPUT_W{data_q_in[INPUT_W-1]}}, data_q_in};

            i_int_reg[0] <= $signed(i_int_reg[0]) + $signed(i_comb_in);
            q_int_reg[0] <= $signed(q_int_reg[0]) + $signed(q_comb_in);

            for (i = 1; i < N; i = i + 1) begin
                i_int_reg[i] <= $signed(i_int_reg[i]) + $signed(i_int_reg[i-1]);
                q_int_reg[i] <= $signed(q_int_reg[i]) + $signed(q_int_reg[i-1]);
            end
        end
    end

    // ============================================================
    // Rate generator
    // ============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rate_counter <= 3'd0;
        end else if (valid_in) begin
            rate_counter <= 3'd1;
        end else if (rate_counter == R) begin
            rate_counter <= 3'd0;
        end else if (high_rate_tick) begin
            rate_counter <= rate_counter + 3'd1;
        end
    end

    // ============================================================
    // Comb filter and scaling to output
    // ============================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < R; i = i + 1) begin
                i_delay_line[i] <= {INTERNAL_W{1'b0}};
                q_delay_line[i] <= {INTERNAL_W{1'b0}};
            end
            for (i = 0; i < N; i = i + 1) begin
                i_comb_out[i] <= {INTERNAL_W{1'b0}};
                q_comb_out[i] <= {INTERNAL_W{1'b0}};
            end
            i_shifted <= {INTERNAL_W{1'b0}};
            q_shifted <= {INTERNAL_W{1'b0}};
            data_i_out <= {OUTPUT_W{1'b0}};
            data_q_out <= {OUTPUT_W{1'b0}};
            valid_out <= 1'b0;
        end else if (high_rate_tick) begin
            // Update delay line
            i_delay_line[0] <= i_int_reg[N-1];
            q_delay_line[0] <= q_int_reg[N-1];
            for (i = 1; i < R; i = i + 1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end

            // Comb stages
            i_comb_out[0] <= $signed(i_int_reg[N-1]) - $signed(i_delay_line[R-1]);
            q_comb_out[0] <= $signed(q_int_reg[N-1]) - $signed(q_delay_line[R-1]);

            i_comb_out[1] <= $signed(i_comb_out[0]) - $signed(i_comb_out[0] >>> R);
            q_comb_out[1] <= $signed(q_comb_out[0]) - $signed(q_comb_out[0] >>> R);

            i_comb_out[2] <= $signed(i_comb_out[1]) - $signed(i_comb_out[1] >>> R);
            q_comb_out[2] <= $signed(q_comb_out[1]) - $signed(q_comb_out[1] >>> R);

            // Proper scaling to 21 bits (fixed syntax issue)
            i_shifted <= i_comb_out[N-1] >>> SHIFT_W;
            q_shifted <= q_comb_out[N-1] >>> SHIFT_W;

            data_i_out <= i_shifted[OUTPUT_W-1:0];
            data_q_out <= q_shifted[OUTPUT_W-1:0];

            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule


