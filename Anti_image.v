
`timescale 1ns / 1ps
// the one which i am using 


/*module AntiImage_FIR (
    input wire clk,
    input wire reset,
    input wire signed [27:0] data_i_in,
    input wire signed [27:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

    localparam TAPS = 10;
    localparam DATA_IN_W = 28;
    localparam COEFF_W = 14;
    localparam DATA_OUT_W = 28;
    localparam MAC_W = DATA_IN_W + COEFF_W + 4;
    localparam SCALE_SHIFT = COEFF_W - 1;
    
    // Coefficients (Q13 format)
    reg signed [COEFF_W-1:0] h [0:TAPS-1];
    
    // Delay lines - ADD SYNTHESIS ATTRIBUTES
    (* syn_preserve = 1 *) (* keep = "true" *) 
    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS-1];
    
    (* syn_preserve = 1 *) (* keep = "true" *) 
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS-1];
    
    initial begin
        h[0] = 14'h00A0;  // 0.0488
        h[1] = 14'h03C0;  // 0.1875
        h[2] = 14'h0BA0;  // 0.5859
        h[3] = 14'h1F80;  // 0.9921
        h[4] = 14'h2000;  // 1.0000 (Center tap)
        h[5] = 14'h1F80;      // Mirror
        h[6] = 14'h0BA0;
        h[7] = 14'h03C0;
        h[8] = 14'h00A0;
        h[9] = 14'd0;
    end
    
    integer i;

    // ========================================================================
    // Delay Line Update - ALWAYS ACTIVE (continuous operation)
    // ========================================================================
    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<TAPS; i=i+1) begin
                i_delay_line[i] <= {DATA_IN_W{1'b0}};
                q_delay_line[i] <= {DATA_IN_W{1'b0}};
            end
        end else begin
            // CRITICAL: Always shift (continuous high-rate operation)
            // Input data at position 0
            i_delay_line[0] <= data_i_in;
            q_delay_line[0] <= data_q_in;
            
            // Shift all other positions
            for (i=1; i<TAPS; i=i+1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
        end
    end

    // ========================================================================
    // MAC Computation (Combinational)
    // ========================================================================
    reg signed [MAC_W-1:0] i_mac_comb;
    reg signed [MAC_W-1:0] q_mac_comb;

    always @* begin
        i_mac_comb = {MAC_W{1'b0}};
        q_mac_comb = {MAC_W{1'b0}};
        
        for (i=0; i < TAPS; i=i+1) begin
            i_mac_comb = $signed(i_mac_comb) + ($signed(h[i]) * $signed(i_delay_line[i]));
            q_mac_comb = $signed(q_mac_comb) + ($signed(h[i]) * $signed(q_delay_line[i]));
        end
    end
    
    // ========================================================================
    // Output Pipeline (2 stages for timing closure)
    // ========================================================================
    reg signed [MAC_W-1:0] i_pipe1, q_pipe1;
    reg signed [DATA_OUT_W-1:0] i_pipe2, q_pipe2;

    always @(posedge clk) begin
        if (reset) begin
            i_pipe1 <= {MAC_W{1'b0}};
            q_pipe1 <= {MAC_W{1'b0}};
            i_pipe2 <= {DATA_OUT_W{1'b0}};
            q_pipe2 <= {DATA_OUT_W{1'b0}};
            data_i_out <= {DATA_OUT_W{1'b0}};
            data_q_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            // Stage 1: Register MAC result
            i_pipe1 <= i_mac_comb;
            q_pipe1 <= q_mac_comb;

            // Stage 2: Scale down
            i_pipe2 <= i_pipe1 >>> SCALE_SHIFT;
            q_pipe2 <= q_pipe1 >>> SCALE_SHIFT;
            
            // Stage 3: Final output
            data_i_out <= i_pipe2;
            data_q_out <= q_pipe2;
            
            // Output is always valid (continuous operation)
            valid_out <= valid_in;
        end
    end
    
endmodule*/

//====================================================================================
// the new one from the cloud AI 


module AntiImage_FIR (
    input wire clk,
    input wire reset,
    input wire signed [27:0] data_i_in,
    input wire signed [27:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

    localparam TAPS = 10;
    localparam DATA_IN_W = 28;
    localparam COEFF_W = 14;
    localparam DATA_OUT_W = 28;
    localparam MAC_W = DATA_IN_W + COEFF_W + 4;
    localparam SCALE_SHIFT = COEFF_W - 1;
    
    reg signed [COEFF_W-1:0] h [0:TAPS-1];
    
    (* syn_preserve = 1 *) (* keep = "true" *) 
    reg signed [DATA_IN_W-1:0] i_delay_line [0:TAPS-1];
    
    (* syn_preserve = 1 *) (* keep = "true" *) 
    reg signed [DATA_IN_W-1:0] q_delay_line [0:TAPS-1];
    
    initial begin
        h[0] = 14'h00A0;  
        h[1] = 14'h03C0;  
        h[2] = 14'h0BA0;  
        h[3] = 14'h1F80;  
        h[4] = 14'h2000;  
        h[5] = 14'h1F80;      
        h[6] = 14'h0BA0;
        h[7] = 14'h03C0;
        h[8] = 14'h00A0;
        h[9] = 14'd0;
    end
    
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i=0; i<TAPS; i=i+1) begin
                i_delay_line[i] <= {DATA_IN_W{1'b0}};
                q_delay_line[i] <= {DATA_IN_W{1'b0}};
            end
        end else begin
            i_delay_line[0] <= data_i_in;
            q_delay_line[0] <= data_q_in;
            
            for (i=1; i<TAPS; i=i+1) begin
                i_delay_line[i] <= i_delay_line[i-1];
                q_delay_line[i] <= q_delay_line[i-1];
            end
        end
    end

    reg signed [MAC_W-1:0] i_mac_comb;
    reg signed [MAC_W-1:0] q_mac_comb;

    always @* begin
        i_mac_comb = {MAC_W{1'b0}};
        q_mac_comb = {MAC_W{1'b0}};
        
        for (i=0; i < TAPS; i=i+1) begin
            i_mac_comb = $signed(i_mac_comb) + ($signed(h[i]) * $signed(i_delay_line[i]));
            q_mac_comb = $signed(q_mac_comb) + ($signed(h[i]) * $signed(q_delay_line[i]));
        end
    end
    
    reg signed [MAC_W-1:0] i_pipe1, q_pipe1;
    reg signed [DATA_OUT_W-1:0] i_pipe2, q_pipe2;

    always @(posedge clk) begin
        if (reset) begin
            i_pipe1 <= {MAC_W{1'b0}};
            q_pipe1 <= {MAC_W{1'b0}};
            i_pipe2 <= {DATA_OUT_W{1'b0}};
            q_pipe2 <= {DATA_OUT_W{1'b0}};
            data_i_out <= {DATA_OUT_W{1'b0}};
            data_q_out <= {DATA_OUT_W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            i_pipe1 <= i_mac_comb;
            q_pipe1 <= q_mac_comb;

            i_pipe2 <= i_pipe1 >>> SCALE_SHIFT;
            q_pipe2 <= q_pipe1 >>> SCALE_SHIFT;
            
            data_i_out <= i_pipe2;
            data_q_out <= q_pipe2;
            
            valid_out <= valid_in;
        end
    end
    
endmodule