

`timescale 1ns / 1ps
/*    the onw which i am using
module Polyphase_FIR (
    input wire clk,
    input wire reset,
    input wire signed [23:0] data_i_in,
    input wire signed [23:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

    localparam R = 10;                      // Interpolation factor
    localparam TAPS_PER_PHASE = 8;          // Taps per polyphase branch
    localparam DATA_IN_W = 24;              // Input data width
    localparam COEFF_W = 14;                // Coefficient width (Q13)
    localparam DATA_OUT_W = 28;             // Output data width
    localparam MAC_W = DATA_IN_W + COEFF_W + 4; // MAC accumulator width
    localparam SCALE_SHIFT = 13;            // Q13 format scaling

    // Delay lines for input samples
    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS_PER_PHASE-1];
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS_PER_PHASE-1];

    // Coefficient storage for all polyphase branches
    // Total coefficients = R * TAPS_PER_PHASE = 10 * 8 = 80
    reg signed [COEFF_W-1:0] h [0:R * TAPS_PER_PHASE-1];
    
    integer k;
    initial begin
        // Initialize coefficients for unity gain
        // Each coefficient contributes to total gain
        // Target: Sum of all coeff magnitudes ≈ 8192 (for Q13 unity gain)
        // 80 taps * 102 ≈ 8160 ≈ unity gain
        for (k=0; k < R * TAPS_PER_PHASE; k=k+1) begin
            h[k] = 14'sd102;  // Approximately unity gain across all phases
        end
    end

    // Phase counter: cycles through 0 to R-1 (0 to 9)
    reg [3:0] phase_counter;
    
    // Active flag: high when generating interpolated outputs
    reg active;
    
    // Loop variables
    integer i, j;
    integer phase;

    // =========================================================================
    // Delay Line and Phase Control Logic
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase_counter <= 4'd0;
            active <= 1'b0;
            
            // Clear delay lines
            for (i=0; i < TAPS_PER_PHASE; i=i+1) begin
                i_delay_line[i] <= {DATA_IN_W{1'b0}};
                q_delay_line[i] <= {DATA_IN_W{1'b0}};
            end
        end 
        else if (valid_in) begin
            // New input sample arrives - shift delay line
            for (i=TAPS_PER_PHASE-1; i>0; i=i-1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
            i_delay_line[0] <= data_i_in;
            q_delay_line[0] <= data_q_in;
            
            // Start generating R interpolated outputs
            phase_counter <= 4'd0;
            active <= 1'b1;
        end 
        else if (active) begin
            // Cycle through phases
            if (phase_counter == R-1) begin
                // Completed all R phases
                phase_counter <= 4'd0;
                active <= 1'b0;
            end else begin
                // Move to next phase
                phase_counter <= phase_counter + 4'd1;
            end
        end
    end

    // =========================================================================
    // Polyphase Filter MAC (Multiply-Accumulate) - Combinational
    // =========================================================================
    reg signed [MAC_W-1:0] i_mac_comb;
    reg signed [MAC_W-1:0] q_mac_comb;

    always @* begin
        i_mac_comb = {MAC_W{1'b0}};
        q_mac_comb = {MAC_W{1'b0}};
        phase = phase_counter;
        
        // Compute MAC for current phase
        // For phase P, use coefficients: h[P], h[P+R], h[P+2R], ..., h[P+7R]
        for (j=0; j < TAPS_PER_PHASE; j=j+1) begin
            i_mac_comb = $signed(i_mac_comb) + 
                         ($signed(h[phase + j * R]) * $signed(i_delay_line[j]));
            q_mac_comb = $signed(q_mac_comb) + 
                         ($signed(h[phase + j * R]) * $signed(q_delay_line[j]));
        end
    end

    // =========================================================================
    // Output Register Stage
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_i_out <= {DATA_OUT_W{1'b0}};
            data_q_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end 
        else begin
            // Scale down from MAC width to output width
            // Right shift by SCALE_SHIFT to account for Q13 format
            data_i_out <= $signed(i_mac_comb) >>> SCALE_SHIFT;
            data_q_out <= $signed(q_mac_comb) >>> SCALE_SHIFT;
            
            // Output is valid when we're actively generating phases
            valid_out <= active;
        end
    end

endmodule*/


//===================================================================================

// the one from the cloud 

module Polyphase_FIR (
    input wire clk,
    input wire reset,
    input wire signed [23:0] data_i_in,
    input wire signed [23:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

    localparam R = 10;                      
    localparam TAPS_PER_PHASE = 8;          
    localparam DATA_IN_W = 24;              
    localparam COEFF_W = 14;                
    localparam DATA_OUT_W = 28;             
    localparam MAC_W = DATA_IN_W + COEFF_W + 4; 
    localparam SCALE_SHIFT = 13;            

    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS_PER_PHASE-1];
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS_PER_PHASE-1];

    reg signed [COEFF_W-1:0] h [0:R * TAPS_PER_PHASE-1];
    
    integer k;
    initial begin
        for (k=0; k < R * TAPS_PER_PHASE; k=k+1) begin
            h[k] = 14'sd102;  
        end
    end

    reg [3:0] phase_counter;
    reg active;
    
    integer i, j;
    integer phase;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase_counter <= 4'd0;
            active <= 1'b0;
            
            for (i=0; i < TAPS_PER_PHASE; i=i+1) begin
                i_delay_line[i] <= {DATA_IN_W{1'b0}};
                q_delay_line[i] <= {DATA_IN_W{1'b0}};
            end
        end 
        else if (valid_in) begin
            for (i=TAPS_PER_PHASE-1; i>0; i=i-1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
            i_delay_line[0] <= data_i_in;
            q_delay_line[0] <= data_q_in;
            
            phase_counter <= 4'd0;
            active <= 1'b1;
        end 
        else if (active) begin
            if (phase_counter == R-1) begin
                phase_counter <= 4'd0;
                active <= 1'b0;
            end else begin
                phase_counter <= phase_counter + 4'd1;
            end
        end
    end

    reg signed [MAC_W-1:0] i_mac_comb;
    reg signed [MAC_W-1:0] q_mac_comb;

    always @* begin
        i_mac_comb = {MAC_W{1'b0}};
        q_mac_comb = {MAC_W{1'b0}};
        phase = phase_counter;
        
        for (j=0; j < TAPS_PER_PHASE; j=j+1) begin
            i_mac_comb = $signed(i_mac_comb) + 
                         ($signed(h[phase + j * R]) * $signed(i_delay_line[j]));
            q_mac_comb = $signed(q_mac_comb) + 
                         ($signed(h[phase + j * R]) * $signed(q_delay_line[j]));
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_i_out <= {DATA_OUT_W{1'b0}};
            data_q_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end 
        else begin
            data_i_out <= $signed(i_mac_comb) >>> SCALE_SHIFT;
            data_q_out <= $signed(q_mac_comb) >>> SCALE_SHIFT;
            valid_out <= active;
        end
    end

endmodule

