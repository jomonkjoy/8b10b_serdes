// 8b/10b Encoder Module
module encoder_8b10b (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] data_in,
    input  logic       k_in,        // Control character indicator
    output logic [9:0] data_out,
    output logic       valid_out
);

    logic running_disparity;  // 0 = negative, 1 = positive
    
    // 5b/6b encoding tables
    function automatic logic [5:0] encode_5b6b(input logic [4:0] data, input logic rd, input logic k);
        logic [5:0] result;
        case(data)
            5'h00: result = rd ? 6'b100111 : 6'b011000;
            5'h01: result = rd ? 6'b011101 : 6'b100010;
            5'h02: result = rd ? 6'b101101 : 6'b010010;
            5'h03: result = 6'b110001;
            5'h04: result = rd ? 6'b110101 : 6'b001010;
            5'h05: result = 6'b101001;
            5'h06: result = 6'b011001;
            5'h07: result = rd ? 6'b111000 : 6'b000111;
            5'h08: result = rd ? 6'b111001 : 6'b000110;
            5'h09: result = 6'b100101;
            5'h0A: result = 6'b010101;
            5'h0B: result = 6'b110100;
            5'h0C: result = 6'b001101;
            5'h0D: result = 6'b101100;
            5'h0E: result = 6'b011100;
            5'h0F: result = rd ? 6'b010111 : 6'b101000;
            5'h10: result = rd ? 6'b011011 : 6'b100100;
            5'h11: result = 6'b100011;
            5'h12: result = 6'b010011;
            5'h13: result = 6'b110010;
            5'h14: result = 6'b001011;
            5'h15: result = 6'b101010;
            5'h16: result = 6'b011010;
            5'h17: result = rd ? 6'b111010 : 6'b000101;
            5'h18: result = rd ? 6'b110011 : 6'b001100;
            5'h19: result = 6'b100110;
            5'h1A: result = 6'b010110;
            5'h1B: result = rd ? 6'b110110 : 6'b001001;
            5'h1C: result = 6'b001110;
            5'h1D: result = rd ? 6'b101110 : 6'b010001;
            5'h1E: result = rd ? 6'b011110 : 6'b100001;
            5'h1F: result = rd ? 6'b101011 : 6'b010100;
        endcase
        return result;
    endfunction
    
    // 3b/4b encoding tables
    function automatic logic [3:0] encode_3b4b(input logic [2:0] data, input logic rd);
        logic [3:0] result;
        case(data)
            3'h0: result = rd ? 4'b1011 : 4'b0100;
            3'h1: result = 4'b1001;
            3'h2: result = 4'b0101;
            3'h3: result = rd ? 4'b1100 : 4'b0011;
            3'h4: result = rd ? 4'b1101 : 4'b0010;
            3'h5: result = 4'b1010;
            3'h6: result = 4'b0110;
            3'h7: result = rd ? 4'b1110 : 4'b0001;
        endcase
        return result;
    endfunction
    
    // Calculate disparity
    function automatic logic calc_disparity(input logic [9:0] code);
        int ones = $countones(code);
        return (ones > 5) ? 1'b1 : 1'b0;
    endfunction
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running_disparity <= 1'b0;
            data_out <= 10'h0;
            valid_out <= 1'b0;
        end else begin
            logic [5:0] code_5b6b;
            logic [3:0] code_3b4b;
            
            code_5b6b = encode_5b6b(data_in[4:0], running_disparity, k_in);
            code_3b4b = encode_3b4b(data_in[7:5], running_disparity);
            
            data_out <= {code_3b4b, code_5b6b};
            valid_out <= 1'b1;
            
            running_disparity <= calc_disparity({code_3b4b, code_5b6b});
        end
    end
endmodule
