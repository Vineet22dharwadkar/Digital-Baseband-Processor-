
`timescale 1ns / 1ps

module cic_interpolator_x5(
    input clk,
    input reset,
    input signed [7:0] data_i_in,
    input signed [7:0] data_q_in,
    input valid_in,
    output reg signed [15:0] data_i_out,
    output reg signed [15:0] data_q_out,
    output reg valid_out
);

    localparam R = 5;
    localparam N = 3;
    localparam INPUT_W = 8;
    localparam OUTPUT_W = 16;
    localparam SHIFT_W = 7;

    // Integrator registers
    reg signed [OUTPUT_W-1:0] i_int_reg [N-1:0];
    reg signed [OUTPUT_W-1:0] q_int_reg [N-1:0];

    // Rate counter
    reg [2:0] rate_counter;
    wire high_rate_tick;

    // Upsampler
    reg signed [OUTPUT_W-1:0] i_comb_in;
    reg signed [OUTPUT_W-1:0] q_comb_in;

    // Delay lines
    reg signed [OUTPUT_W-1:0] i_delay_line [R-1:0];
    reg signed [OUTPUT_W-1:0] q_delay_line [R-1:0];

    // Comb outputs
    reg signed [OUTPUT_W-1:0] i_comb_out [N-1:0];
    reg signed [OUTPUT_W-1:0] q_comb_out [N-1:0];

    integer i;

    // Integrators
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            for (i=0; i<N; i=i+1) begin
                i_int_reg[i] <= {OUTPUT_W{1'b0}};
                q_int_reg[i] <= {OUTPUT_W{1'b0}};
            end
        end else if (valid_in) begin
            i_int_reg[0] <= $signed(i_int_reg[0]) + $signed({{OUTPUT_W-INPUT_W{data_i_in[INPUT_W-1]}}, data_i_in});
            i_int_reg[1] <= $signed(i_int_reg[1]) + $signed(i_int_reg[0]);
            i_int_reg[2] <= $signed(i_int_reg[2]) + $signed(i_int_reg[1]);
            
            q_int_reg[0] <= $signed(q_int_reg[0]) + $signed({{OUTPUT_W-INPUT_W{data_q_in[INPUT_W-1]}}, data_q_in});
            q_int_reg[1] <= $signed(q_int_reg[1]) + $signed(q_int_reg[0]);
            q_int_reg[2] <= $signed(q_int_reg[2]) + $signed(q_int_reg[1]);
        end
    end

    // Rate generator
    assign high_rate_tick = (rate_counter > 3'd0);

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

    // Upsampler
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            i_comb_in <= {OUTPUT_W{1'b0}};
            q_comb_in <= {OUTPUT_W{1'b0}};
        end else if(valid_in) begin
            i_comb_in <= i_int_reg[N-1];
            q_comb_in <= q_int_reg[N-1];
        end
    end

    // Comb filter
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i=0; i<N; i=i+1) begin
                i_comb_out[i] <= {OUTPUT_W{1'b0}};
                q_comb_out[i] <= {OUTPUT_W{1'b0}};
            end
            for (i=0; i<R; i=i+1) begin
                i_delay_line[i] <= {OUTPUT_W{1'b0}};
                q_delay_line[i] <= {OUTPUT_W{1'b0}};
            end
            data_i_out <= {OUTPUT_W{1'b0}};
            data_q_out <= {OUTPUT_W{1'b0}};
            valid_out <= 1'b0;
        end else if (high_rate_tick) begin
            // Update delay line
            i_delay_line[0] <= i_comb_in;
            q_delay_line[0] <= q_comb_in;
            for (i=1; i<R; i=i+1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end

            // Comb stages
            i_comb_out[0] <= $signed(i_comb_in) - $signed(i_delay_line[R-1]);
            q_comb_out[0] <= $signed(q_comb_in) - $signed(q_delay_line[R-1]);
            
            i_comb_out[1] <= $signed(i_comb_out[0]) - $signed(i_comb_out[0] >>> R);
            q_comb_out[1] <= $signed(q_comb_out[0]) - $signed(q_comb_out[0] >>> R);

            i_comb_out[2] <= $signed(i_comb_out[1]) - $signed(i_comb_out[1] >>> R);
            q_comb_out[2] <= $signed(q_comb_out[1]) - $signed(q_comb_out[1] >>> R);

            // Output with scaling
            data_i_out <= $signed(i_comb_out[N-1]) >>> SHIFT_W;
            data_q_out <= $signed(q_comb_out[N-1]) >>> SHIFT_W;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule




