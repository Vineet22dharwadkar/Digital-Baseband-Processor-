`timescale 1ns / 1ps
// =========================================================================
// TESTBENCH: DSP_Top Module (Digital Up Converter)
// 1. FIXED: Replaced non-standard 'break' keyword with a 'stop_test_flag'.
// 2. ADDED: File writing for I and Q outputs.
// 3. FIXED: Improved stimulus timing and added initial latency wait.
// =========================================================================

/*module test_bench;

    // --- 1. DUT Interface Signals ---
    reg clk;
    reg reset;
    reg signed [7:0] data_i_in_low;
    reg signed [7:0] data_q_in_low;
    reg valid_in_low;

    wire signed [27:0] data_i_out_high;
    wire signed [27:0] data_q_out_high;
    wire valid_out_high;

    // --- 2. Simulation Control Registers & Parameters ---
    parameter CLK_PERIOD = 10;   // 100 MHz clock (10 ns period)
    parameter INTERP_RATIO = 250; // Total interpolation factor (5*5*10)

    integer low_rate_counter; // Counts CLK cycles (0 to 249)
    integer i;                // Loop/Sample counter
    reg stop_test_flag;       // Used to gracefully terminate the simulation loop

    // File handles
    integer file_i_in_handle, file_q_in_handle;
    integer file_i_out_handle, file_q_out_handle;
    reg [63:0] input_data_i, input_data_q; // Temp registers for $fscanf

    // Estimated pipeline latency (must be waited for before first valid output)
    // Approx Latency = 1 (Input) + 3 (CIC1) + 2 (CFIR) + 3 (CIC2) + 2 (PFIR) + 3 (Poly) + 2 (Anti) + 2 (NCO) = ~18 clocks
    parameter PIPELINE_LATENCY_CLKS = 25; // Use a conservative value

    // --- 3. DUT Instantiation ---
    DSP_Top DUT (
        .clk(clk),
        .reset(reset),
        .data_i_in_low(data_i_in_low),
        .data_q_in_low(data_q_in_low),
        .valid_in_low(valid_in_low),

        .data_i_out_high(data_i_out_high),
        .data_q_out_high(data_q_out_high),
        .valid_out_high(valid_out_high)
    );


    // --- 4. Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    // --- 5. Test Stimulus and Control ---
    initial begin
        // Initialize inputs
        reset = 1'b1;
        valid_in_low = 1'b0;
        data_i_in_low = 8'd0;
        data_q_in_low = 8'd0;
        low_rate_counter = 0;
        i = 0;
        stop_test_flag = 1'b0;

        // Open stimulus files
        file_i_in_handle = $fopen("I_int8_hex.txt", "r");
        file_q_in_handle = $fopen("Q_int8_hex.txt", "r");

        // Open output files for writing
        file_i_out_handle = $fopen("duc_i_out.txt", "w");
        file_q_out_handle = $fopen("duc_q_out.txt", "w");

        if (file_i_in_handle == 0 || file_q_in_handle == 0) begin
            $display("ERROR: Could not open input files. Check file paths.");
            $finish;
        end
        if (file_i_out_handle == 0 || file_q_out_handle == 0) begin
            $display("ERROR: Could not open output files for writing.");
            $finish;
        end


        // Start of Reset Sequence
        $display("------------------------------------------------------------------");
        $display("Simulation Started. Applying Reset.");
        $display("------------------------------------------------------------------");
        # (CLK_PERIOD * 5); // Hold reset for 5 clocks
        reset = 1'b0; // Deassert reset
        @(posedge clk); // Wait one more cycle after reset release


        // --- CORE STIMULUS LOOP (High-Rate Operation) ---
        // We clock the system at 100MHz (high rate) and control the input CE
        // based on the low_rate_counter.
        
        while (!stop_test_flag) begin
            @(posedge clk);
            
            // 1. Check for Low-Rate Input Tick (Input CE should be active every 250 clocks)
            if (low_rate_counter == 0) begin
                valid_in_low = 1'b1;
                
                // Read the next sample from files
                if ($fscanf(file_i_in_handle, "%h", input_data_i) && $fscanf(file_q_in_handle, "%h", input_data_q)) begin
                    // Assign new input data
                    data_i_in_low = input_data_i;
                    data_q_in_low = input_data_q;
                    i = i + 1;
                    
                    // Display current input sample
                    $display("Time: %t | Sample %d INPUT: I=%h, Q=%h (Valid Low)", $time, i, data_i_in_low, data_q_in_low);
                end else begin
                    // EOF reached or file read error, stop test elegantly
                    $display("--- End of input file reached. %d samples read. ---", i);
                    stop_test_flag = 1'b1;
                end
            end else begin
                valid_in_low = 1'b0; // Deassert valid on all other cycles
            end
            
            // Increment the counter and wrap it around at INTERP_RATIO
            low_rate_counter = low_rate_counter + 1;
            if (low_rate_counter == INTERP_RATIO) begin
                low_rate_counter = 0;
            end
            
            // Check if we are past the latency and have valid output data
            if ($time > (CLK_PERIOD * PIPELINE_LATENCY_CLKS) && valid_out_high) begin
                // --- WRITE TO FILE (HIGH-RATE) ---
                // Data is 28-bit signed. Displaying in Hex (7 digits)
                $fdisplay(file_i_out_handle, "%h", data_i_out_high);
                $fdisplay(file_q_out_handle, "%h", data_q_out_high);

                // Monitoring (Optional)
                $strobe("Time: %t | OUTPUT: I=%h, Q=%h (Valid High)", $time, data_i_out_high, data_q_out_high);
            end

        end
        

        // --- 6. Simulation End Sequence ---
        $fclose(file_i_in_handle);
        $fclose(file_q_in_handle);
        $fclose(file_i_out_handle);
        $fclose(file_q_out_handle);

        $display("------------------------------------------------------------------");
        $display("Stimulus finished. Waiting for final pipeline flush...");
        $display("------------------------------------------------------------------");

        // Wait a few extra clock cycles for the DUT pipeline to flush completely
        # (CLK_PERIOD * 100);

        $display("Test Bench Complete. Output written to duc_i_out.txt and duc_q_out.txt");
        $finish;

    end

endmodule*/


`timescale 1ns / 1ps

module test_bench;

    reg clk;
    reg reset;
    reg signed [7:0] data_i_in_low;
    reg signed [7:0] data_q_in_low;
    reg valid_in_low;

    wire signed [27:0] data_i_out_high;
    wire signed [27:0] data_q_out_high;
    wire valid_out_high;

    parameter CLK_PERIOD = 10;
    parameter INTERP_RATIO = 250;

    integer low_rate_counter;
    integer i;
    reg stop_test_flag;

    integer file_i_in_handle, file_q_in_handle;
    integer file_i_out_handle, file_q_out_handle;
    integer scan_result_i, scan_result_q;
    reg [7:0] input_data_i, input_data_q;

    parameter PIPELINE_LATENCY_CLKS = 50;
    integer output_sample_count;

    DSP_Top DUT (
        .clk(clk),
        .reset(reset),
        .data_i_in_low(data_i_in_low),
        .data_q_in_low(data_q_in_low),
        .valid_in_low(valid_in_low),
        .data_i_out_high(data_i_out_high),
        .data_q_out_high(data_q_out_high),
        .valid_out_high(valid_out_high)
    );

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        valid_in_low = 1'b0;
        data_i_in_low = 8'd0;
        data_q_in_low = 8'd0;
        low_rate_counter = 0;
        i = 0;
        stop_test_flag = 1'b0;
        output_sample_count = 0;

        file_i_in_handle = $fopen("I_int8_5m.txt", "r");
        file_q_in_handle = $fopen("Q_int8_5m.txt", "r");
        file_i_out_handle = $fopen("duc_i_out.txt", "w");
        file_q_out_handle = $fopen("duc_q_out.txt", "w");

        if (file_i_in_handle == 0 || file_q_in_handle == 0) begin
            $display("ERROR: Could not open input files.");
            $finish;
        end

        $display("========================================");
        $display("DUC Testbench Starting");
        $display("========================================");
        
        #(CLK_PERIOD * 10);
        reset = 1'b0;
        $display("Reset released at time %t", $time);
        
        #(CLK_PERIOD * 5);

        while (!stop_test_flag) begin
            @(posedge clk);
            
            if (low_rate_counter == 0) begin
                scan_result_i = $fscanf(file_i_in_handle, "%h", input_data_i);
                scan_result_q = $fscanf(file_q_in_handle, "%h", input_data_q);
                
                if (scan_result_i == 1 && scan_result_q == 1) begin
                    valid_in_low = 1'b1;
                    data_i_in_low = $signed(input_data_i);
                    data_q_in_low = $signed(input_data_q);
                    i = i + 1;
                    
                    if (i <= 10 || i % 100 == 0) begin
                        $display("Input Sample %0d: I=%h (%0d), Q=%h (%0d)", 
                                 i, data_i_in_low, $signed(data_i_in_low), 
                                 data_q_in_low, $signed(data_q_in_low));
                    end
                end else begin
                    $display("End of input files at sample %0d", i);
                    stop_test_flag = 1'b1;
                    valid_in_low = 1'b0;
                end
            end else begin
                valid_in_low = 1'b0;
            end
            
            low_rate_counter = low_rate_counter + 1;
            if (low_rate_counter >= INTERP_RATIO) begin
                low_rate_counter = 0;
            end
            
            if (valid_out_high && ($time > (CLK_PERIOD * PIPELINE_LATENCY_CLKS))) begin
                $fwrite(file_i_out_handle, "%h\n", data_i_out_high);
                $fwrite(file_q_out_handle, "%h\n", data_q_out_high);
                output_sample_count = output_sample_count + 1;
                
                if (output_sample_count <= 20 || output_sample_count % 1000 == 0) begin
                    $display("Output Sample %0d: I=%h (%0d), Q=%h (%0d)", 
                             output_sample_count, data_i_out_high, $signed(data_i_out_high),
                             data_q_out_high, $signed(data_q_out_high));
                end
            end
        end

        #(CLK_PERIOD * 500);

        $fclose(file_i_in_handle);
        $fclose(file_q_in_handle);
        $fclose(file_i_out_handle);
        $fclose(file_q_out_handle);

        $display("========================================");
        $display("Simulation Complete");
        $display("Input samples: %0d", i);
        $display("Output samples: %0d", output_sample_count);
        $display("Expected output: %0d", i * INTERP_RATIO);
        $display("========================================");
        
        $finish;
    end

endmodule