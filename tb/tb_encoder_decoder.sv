// Additional testbench for individual component testing
module tb_encoder_decoder;
    
    logic       clk;
    logic       rst_n;
    logic [7:0] data_in;
    logic       k_in;
    logic [9:0] encoded;
    logic       enc_valid;
    logic [7:0] decoded;
    logic       k_out;
    logic       dec_valid;
    logic       disp_err;
    logic       code_err;
    
    // Instantiate encoder
    encoder_8b10b enc (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .k_in(k_in),
        .data_out(encoded),
        .valid_out(enc_valid)
    );
    
    // Instantiate decoder
    decoder_8b10b dec (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(encoded),
        .valid_in(enc_valid),
        .data_out(decoded),
        .k_out(k_out),
        .valid_out(dec_valid),
        .disp_err(disp_err),
        .code_err(code_err)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        rst_n = 0;
        data_in = 8'h00;
        k_in = 1'b0;
        
        #20 rst_n = 1;
        
        $display("\n=== Encoder/Decoder Unit Test ===\n");
        
        // Test various data patterns
        for (int i = 0; i < 256; i++) begin
            @(posedge clk);
            data_in <= i;
            k_in <= 1'b0;
            
            // Wait for decode and check
            repeat(2) @(posedge clk);
            if (dec_valid && decoded !== i) begin
                $display("ERROR: Mismatch at data=0x%02h, got 0x%02h", i, decoded);
            end
        end
        
        // Test K-codes
        $display("\nTesting K-codes...");
        logic [7:0] k_codes[] = '{8'h1C, 8'h3C, 8'h5C, 8'h7C, 8'h9C, 8'hBC, 8'hDC, 8'hFC};
        foreach (k_codes[i]) begin
            @(posedge clk);
            data_in <= k_codes[i];
            k_in <= 1'b1;
            
            repeat(2) @(posedge clk);
            if (dec_valid && (decoded !== k_codes[i] || !k_out)) begin
                $display("ERROR: K-code mismatch at 0x%02h", k_codes[i]);
            end else if (dec_valid) begin
                $display("K-code 0x%02h encoded as 0b%010b", k_codes[i], encoded);
            end
        end
        
        $display("\n=== Encoder/Decoder Unit Test Complete ===\n");
        #100;
        $finish;
    end
    
endmodule
