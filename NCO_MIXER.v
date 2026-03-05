

// which one i am using 
/*`timescale 1ns / 1ps

module NCO_Mixer (
    input wire clk,
    input wire reset,
    input wire signed [27:0] data_i_in,
    input wire signed [27:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

localparam DATA_W = 28;
localparam PHASE_W = 32;
localparam COS_SIN_W = 16;
localparam MAC_W = DATA_W + COS_SIN_W; // 44
localparam SCALE_SHIFT = COS_SIN_W - 1; // 15

// ✅ FIX FOR SYNTHESIS WARNINGS - BIT-WIDTH OPTIMIZATION
// Only use the significant input bits that affect the output
localparam INPUT_WIDTH = 24;  // Use lower 24 bits from input
localparam INPUT_LSB = 0;     // Starting from bit 0

// Internal signals for bit-selected inputs
wire signed [INPUT_WIDTH-1:0] data_i_in_used;
wire signed [INPUT_WIDTH-1:0] data_q_in_used;

// Extract only the bits that affect the output after multiplication and scaling
assign data_i_in_used = data_i_in[INPUT_LSB +: INPUT_WIDTH];  // Extract [23:0]
assign data_q_in_used = data_q_in[INPUT_LSB +: INPUT_WIDTH];  // Extract [23:0]
// ✅ END OF FIX

// FTW for 29.90 MHz at 100.4 MHz clock
localparam [PHASE_W-1:0] FTW = 32'h4C3DC4DF;

reg [PHASE_W-1:0] phase_acc;

// 1024-entry signed 16-bit sine/cosine LUTs
reg signed [COS_SIN_W-1:0] cos_lut [0:1023];
reg signed [COS_SIN_W-1:0] sin_lut [0:1023];

// Synthesis-friendly ROM initialization
initial begin
    // Each file: 1024 lines, 16-bit signed hex (two's complement), no "0x"
    $readmemh("cos_lut.mem", cos_lut);
    $readmemh("sine_lut.mem", sin_lut);
end

// Phase indexing (10 MSBs -> 1024)
wire [9:0] phase_idx = phase_acc[PHASE_W-1:PHASE_W-10];

// Phase accumulator
always @(posedge clk or posedge reset) begin
    if (reset)
        phase_acc <= {PHASE_W{1'b0}};
    else
        phase_acc <= phase_acc + FTW;
end

// ROM read pipeline
reg signed [COS_SIN_W-1:0] cos_out, sin_out;

always @(posedge clk) begin
    cos_out <= cos_lut[phase_idx];
    sin_out <= sin_lut[phase_idx];
end

// Mix - Complex multiplication: (I + jQ) * (cos + j*sin)
reg signed [MAC_W-1:0] term1_i_reg, term2_i_reg, term1_q_reg, term2_q_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        term1_i_reg <= {MAC_W{1'b0}};
        term2_i_reg <= {MAC_W{1'b0}};
        term1_q_reg <= {MAC_W{1'b0}};
        term2_q_reg <= {MAC_W{1'b0}};
        data_i_out <= {DATA_W{1'b0}};
        data_q_out <= {DATA_W{1'b0}};
        valid_out <= 1'b0;
    end else begin
        // ✅ MODIFIED: Use bit-selected inputs instead of full-width inputs
        term1_i_reg <= $signed(data_i_in_used) * $signed(cos_out); // I*cos
        term2_i_reg <= $signed(data_q_in_used) * $signed(sin_out); // Q*sin
        term1_q_reg <= $signed(data_i_in_used) * $signed(sin_out); // I*sin
        term2_q_reg <= $signed(data_q_in_used) * $signed(cos_out); // Q*cos
        // ✅ END OF MODIFICATION
        
        // Complex multiplication result: I_out = I*cos - Q*sin, Q_out = I*sin + Q*cos
        data_i_out <= ($signed(term1_i_reg) - $signed(term2_i_reg)) >>> SCALE_SHIFT;
        data_q_out <= ($signed(term1_q_reg) + $signed(term2_q_reg)) >>> SCALE_SHIFT;
        valid_out <= 1'b1; // or tie to valid_in if your downstream expects gated-valid
    end
end

endmodule*/


//=========================================================================================
// new one from the cloud 
/*module NCO_Mixer (
    input wire clk,
    input wire reset,
    input wire signed [27:0] data_i_in,
    input wire signed [27:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

localparam DATA_W = 28;
localparam PHASE_W = 32;
localparam COS_SIN_W = 16;
localparam MAC_W = DATA_W + COS_SIN_W; 
localparam SCALE_SHIFT = COS_SIN_W - 1; 

localparam [PHASE_W-1:0] FTW = 32'h4C3DC4DF;

reg [PHASE_W-1:0] phase_acc;

reg signed [COS_SIN_W-1:0] cos_lut [0:1023];
reg signed [COS_SIN_W-1:0] sin_lut [0:1023];

initial begin
    $readmemh("cos_lut.mem", cos_lut);
    $readmemh("sine_lut.mem", sin_lut);
end

wire [9:0] phase_idx = phase_acc[PHASE_W-1:PHASE_W-10];

always @(posedge clk or posedge reset) begin
    if (reset)
        phase_acc <= {PHASE_W{1'b0}};
    else
        phase_acc <= phase_acc + FTW;
end

reg signed [COS_SIN_W-1:0] cos_out, sin_out;

always @(posedge clk) begin
    cos_out <= cos_lut[phase_idx];
    sin_out <= sin_lut[phase_idx];
end

reg signed [MAC_W-1:0] term1_i_reg, term2_i_reg, term1_q_reg, term2_q_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        term1_i_reg <= {MAC_W{1'b0}};
        term2_i_reg <= {MAC_W{1'b0}};
        term1_q_reg <= {MAC_W{1'b0}};
        term2_q_reg <= {MAC_W{1'b0}};
        data_i_out <= {DATA_W{1'b0}};
        data_q_out <= {DATA_W{1'b0}};
        valid_out <= 1'b0;
    end else begin
        term1_i_reg <= $signed(data_i_in) * $signed(cos_out); 
        term2_i_reg <= $signed(data_q_in) * $signed(sin_out); 
        term1_q_reg <= $signed(data_i_in) * $signed(sin_out); 
        term2_q_reg <= $signed(data_q_in) * $signed(cos_out); 
        
        data_i_out <= ($signed(term1_i_reg) - $signed(term2_i_reg)) >>> SCALE_SHIFT;
        data_q_out <= ($signed(term1_q_reg) + $signed(term2_q_reg)) >>> SCALE_SHIFT;
        valid_out <= valid_in;
    end
end

endmodule*/



//===================================================================================================
//gemini new code 

`timescale 1ns / 1ps

module NCO_Mixer (
    input wire clk,
    input wire reset,
    input wire signed [27:0] data_i_in,
    input wire signed [27:0] data_q_in,
    input wire valid_in,
    output reg signed [27:0] data_i_out,
    output reg signed [27:0] data_q_out,
    output reg valid_out
);

// --- Parameter Definitions ---
localparam DATA_W = 28;
localparam PHASE_W = 32;
localparam COS_SIN_W = 16;
localparam MAC_W = DATA_W + COS_SIN_W;      // 44 bits
localparam SCALE_SHIFT = COS_SIN_W - 1;     // 15 bits

// FTW for 30 MHz at 100 MHz clock
localparam [PHASE_W-1:0] FTW = 32'h4CCCCCCD; // 30.000000 MHz

// --- NCO Phase Accumulator (GATED - CRITICAL!) ---
reg [PHASE_W-1:0] phase_acc;

always @(posedge clk or posedge reset) begin
    if (reset)
        phase_acc <= {PHASE_W{1'b0}};
    else if (valid_in)  // ✅ CRITICAL: Only advance when valid data arrives
        phase_acc <= phase_acc + FTW;
end

// Phase Indexing: Use 10 MSBs for 1024-entry LUT
wire [9:0] phase_idx = phase_acc[PHASE_W-1:PHASE_W-10];

// --- Sine/Cosine LUT ---
reg signed [COS_SIN_W-1:0] cos_lut [0:1023];
reg signed [COS_SIN_W-1:0] sin_lut [0:1023];

initial begin
    $readmemh("cos_lut.mem", cos_lut);
    $readmemh("sine_lut.mem", sin_lut);
end

// --- Pipeline Stage 1: ROM Read + Input Registration ---
// ✅ SYNCHRONIZED: Data and carrier read together
reg signed [COS_SIN_W-1:0] cos_reg, sin_reg;
reg signed [DATA_W-1:0] data_i_reg, data_q_reg;
reg valid_reg1;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cos_reg <= {COS_SIN_W{1'b0}};
        sin_reg <= {COS_SIN_W{1'b0}};
        data_i_reg <= {DATA_W{1'b0}};
        data_q_reg <= {DATA_W{1'b0}};
        valid_reg1 <= 1'b0;
    end else if (valid_in) begin
        // Read carrier from LUT
        cos_reg <= cos_lut[phase_idx];
        sin_reg <= sin_lut[phase_idx];
        // Register input data (NO TRUNCATION - use all 28 bits!)
        data_i_reg <= data_i_in;
        data_q_reg <= data_q_in;
        valid_reg1 <= 1'b1;
    end else begin
        valid_reg1 <= 1'b0;
    end
end

// --- Pipeline Stage 2: Multiplication ---
reg signed [MAC_W-1:0] i_cos_term;  // I * cos
reg signed [MAC_W-1:0] q_sin_term;  // Q * sin
reg signed [MAC_W-1:0] i_sin_term;  // I * sin
reg signed [MAC_W-1:0] q_cos_term;  // Q * cos
reg valid_reg2;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        i_cos_term <= {MAC_W{1'b0}};
        q_sin_term <= {MAC_W{1'b0}};
        i_sin_term <= {MAC_W{1'b0}};
        q_cos_term <= {MAC_W{1'b0}};
        valid_reg2 <= 1'b0;
    end else if (valid_reg1) begin
        // Complex multiplication terms
        i_cos_term <= $signed(data_i_reg) * $signed(cos_reg);
        q_sin_term <= $signed(data_q_reg) * $signed(sin_reg);
        i_sin_term <= $signed(data_i_reg) * $signed(sin_reg);
        q_cos_term <= $signed(data_q_reg) * $signed(cos_reg);
        valid_reg2 <= 1'b1;
    end else begin
        valid_reg2 <= 1'b0;
    end
end

// --- Pipeline Stage 3: Addition/Subtraction and Scaling ---
// Complex multiplication: (I + jQ) * (cos + j*sin)
// I_out = I*cos - Q*sin
// Q_out = I*sin + Q*cos

always @(posedge clk or posedge reset) begin
    if (reset) begin
        data_i_out <= {DATA_W{1'b0}};
        data_q_out <= {DATA_W{1'b0}};
        valid_out <= 1'b0;
    end else if (valid_reg2) begin
        // Perform subtraction/addition and scale down by 2^15
        data_i_out <= ($signed(i_cos_term) - $signed(q_sin_term)) >>> SCALE_SHIFT;
        data_q_out <= ($signed(i_sin_term) + $signed(q_cos_term)) >>> SCALE_SHIFT;
        valid_out <= 1'b1;  // ✅ CORRECT: Only high when we output valid data
    end else begin
        valid_out <= 1'b0;  // ✅ CRITICAL: Clear when no valid output
    end
end

endmodule

