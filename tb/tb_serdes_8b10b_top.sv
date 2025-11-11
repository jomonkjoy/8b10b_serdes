`timescale 1ns / 1ps

module tb_serdes_8b10b_top;

    // Clock parameters
    localparam real CLK_PARALLEL_PERIOD = 10.0;  // 100 MHz
    localparam real CLK_SERIAL_PERIOD = 1.0;     // 1 GHz
    
    // Testbench signals
    logic       clk_parallel;
    logic       clk_serial;
    logic       rst_n;
    logic [7:0] tx_data;
    logic       tx_k;
    logic       serial_out;
    logic       serial_in;
    logic [7:0] rx_data;
    logic       rx_k;
    logic       rx_valid;
    logic       rx_disp_err;
    logic       rx_code_err;
    
    // Test control signals
    logic [7:0] expected_data;
    logic       expected_k;
    int         test_count;
    int         error_count;
    int         pass_count;
    
    // Queue for sent data tracking
    typedef struct {
        logic [7:0] data;
        logic       k;
    } tx_packet_t;
    
    tx_packet_t tx_queue[$];
    
    // DUT instantiation
    serdes_8b10b_top dut (
        .clk_parallel(clk_parallel),
        .clk_serial(clk_serial),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_k(tx_k),
        .serial_out(serial_out),
        .serial_in(serial_in),
        .rx_data(rx_data),
        .rx_k(rx_k),
        .rx_valid(rx_valid),
        .rx_disp_err(rx_disp_err),
        .rx_code_err(rx_code_err)
    );
    
    // Loopback connection
    assign serial_in = serial_out;
    
    // Clock generation - Parallel clock
    initial begin
        clk_parallel = 0;
        forever #(CLK_PARALLEL_PERIOD/2) clk_parallel = ~clk_parallel;
    end
    
    // Clock generation - Serial clock (10x faster)
    initial begin
        clk_serial = 0;
        forever #(CLK_SERIAL_PERIOD/2) clk_serial = ~clk_serial;
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        $display("=== Reset Complete at time %0t ===", $time);
    end
    
    // Task to send data
    task automatic send_data(input logic [7:0] data, input logic k_char);
        tx_packet_t pkt;
        @(posedge clk_parallel);
        tx_data <= data;
        tx_k <= k_char;
        pkt.data = data;
        pkt.k = k_char;
        tx_queue.push_back(pkt);
        $display("[TX] Time=%0t: Sending %s = 0x%02h", 
                 $time, k_char ? "K-code" : "Data", data);
    endtask
    
    // Task to send multiple bytes
    task automatic send_packet(input logic [7:0] data_array[], input logic is_k[]);
        for (int i = 0; i < data_array.size(); i++) begin
            send_data(data_array[i], is_k[i]);
        end
    endtask
    
    // Monitor received data
    always @(posedge clk_parallel) begin
        if (rst_n && rx_valid) begin
            tx_packet_t expected_pkt;
            
            if (tx_queue.size() > 0) begin
                // Allow some latency for the data to propagate
                #1;
                expected_pkt = tx_queue.pop_front();
                test_count++;
                
                if (rx_data === expected_pkt.data && rx_k === expected_pkt.k) begin
                    pass_count++;
                    $display("[RX] Time=%0t: ✓ PASS - Received %s = 0x%02h (Expected: 0x%02h)", 
                             $time, rx_k ? "K-code" : "Data", rx_data, expected_pkt.data);
                end else begin
                    error_count++;
                    $display("[RX] Time=%0t: ✗ FAIL - Received %s = 0x%02h (Expected: %s = 0x%02h)", 
                             $time, rx_k ? "K-code" : "Data", rx_data,
                             expected_pkt.k ? "K-code" : "Data", expected_pkt.data);
                end
                
                if (rx_disp_err) begin
                    $display("[RX] Time=%0t: ⚠ WARNING - Disparity Error detected!", $time);
                end
                
                if (rx_code_err) begin
                    $display("[RX] Time=%0t: ⚠ WARNING - Code Error detected!", $time);
                end
            end
        end
    end
    
    // Main test stimulus
    initial begin
        // Initialize
        tx_data = 8'h00;
        tx_k = 1'b0;
        test_count = 0;
        error_count = 0;
        pass_count = 0;
        
        // Wait for reset
        wait(rst_n);
        repeat(10) @(posedge clk_parallel);
        
        $display("\n=== Starting Tests at time %0t ===\n", $time);
        
        // Test 1: Send sequential data
        $display("--- Test 1: Sequential Data Pattern ---");
        for (int i = 0; i < 16; i++) begin
            send_data(i, 1'b0);
        end
        repeat(30) @(posedge clk_parallel);
        
        // Test 2: Send common K-codes
        $display("\n--- Test 2: K-Codes (Control Characters) ---");
        send_data(8'h1C, 1'b1);  // K28.0
        send_data(8'h3C, 1'b1);  // K28.1
        send_data(8'h5C, 1'b1);  // K28.2
        send_data(8'h7C, 1'b1);  // K28.3
        send_data(8'h9C, 1'b1);  // K28.4
        send_data(8'hBC, 1'b1);  // K28.5 (Comma)
        send_data(8'hDC, 1'b1);  // K28.6
        send_data(8'hFC, 1'b1);  // K28.7
        repeat(30) @(posedge clk_parallel);
        
        // Test 3: Mixed data and K-codes
        $display("\n--- Test 3: Mixed Data and K-Codes ---");
        send_data(8'hBC, 1'b1);  // K28.5 - Start of packet
        send_data(8'h12, 1'b0);  // Data
        send_data(8'h34, 1'b0);  // Data
        send_data(8'h56, 1'b0);  // Data
        send_data(8'h78, 1'b0);  // Data
        send_data(8'hFC, 1'b1);  // K28.7 - End of packet
        repeat(30) @(posedge clk_parallel);
        
        // Test 4: All zeros and all ones
        $display("\n--- Test 4: Edge Cases (0x00, 0xFF) ---");
        send_data(8'h00, 1'b0);
        send_data(8'hFF, 1'b0);
        send_data(8'h00, 1'b0);
        send_data(8'hFF, 1'b0);
        repeat(30) @(posedge clk_parallel);
        
        // Test 5: Alternating patterns
        $display("\n--- Test 5: Alternating Patterns ---");
        send_data(8'hAA, 1'b0);
        send_data(8'h55, 1'b0);
        send_data(8'hAA, 1'b0);
        send_data(8'h55, 1'b0);
        repeat(30) @(posedge clk_parallel);
        
        // Test 6: Random data pattern
        $display("\n--- Test 6: Random Data Pattern ---");
        for (int i = 0; i < 20; i++) begin
            logic [7:0] random_data = $urandom_range(0, 255);
            send_data(random_data, 1'b0);
        end
        repeat(40) @(posedge clk_parallel);
        
        // Test 7: Continuous packet transmission
        $display("\n--- Test 7: Continuous Packet Stream ---");
        for (int pkt = 0; pkt < 5; pkt++) begin
            send_data(8'hBC, 1'b1);  // K28.5 - Start
            for (int i = 0; i < 8; i++) begin
                send_data(8'h10 + pkt*16 + i, 1'b0);
            end
            send_data(8'hFC, 1'b1);  // K28.7 - End
        end
        repeat(60) @(posedge clk_parallel);
        
        // Test 8: Back-to-back K-codes
        $display("\n--- Test 8: Back-to-Back K-Codes ---");
        send_data(8'hBC, 1'b1);  // K28.5
        send_data(8'h3C, 1'b1);  // K28.1
        send_data(8'h5C, 1'b1);  // K28.2
        send_data(8'h7C, 1'b1);  // K28.3
        repeat(30) @(posedge clk_parallel);
        
        // Test 9: Long data burst
        $display("\n--- Test 9: Long Data Burst (64 bytes) ---");
        for (int i = 0; i < 64; i++) begin
            send_data(i % 256, 1'b0);
        end
        repeat(80) @(posedge clk_parallel);
        
        // Wait for all data to be received
        repeat(50) @(posedge clk_parallel);
        
        // Print test results
        $display("\n=======================================================");
        $display("              TEST SUMMARY");
        $display("=======================================================");
        $display("Total Tests:    %0d", test_count);
        $display("Passed:         %0d", pass_count);
        $display("Failed:         %0d", error_count);
        $display("Success Rate:   %.2f%%", (pass_count * 100.0) / test_count);
        $display("=======================================================");
        
        if (error_count == 0) begin
            $display("\n✓ ALL TESTS PASSED!\n");
        end else begin
            $display("\n✗ SOME TESTS FAILED!\n");
        end
        
        #1000;
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #1000000;  // 1ms timeout
        $display("\n⚠ ERROR: Simulation timeout!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("serdes_8b10b.vcd");
        $dumpvars(0, tb_serdes_8b10b_top);
    end
    
    // Monitor for debugging
    initial begin
        if ($test$plusargs("DEBUG")) begin
            forever begin
                @(posedge clk_parallel);
                $display("[DEBUG] Time=%0t: serial_out=%b, serial_in=%b, rx_valid=%b", 
                         $time, serial_out, serial_in, rx_valid);
            end
        end
    end

endmodule
