// 8b/10b Decoder Module
module decoder_8b10b (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [9:0] data_in,
    input  logic       valid_in,
    output logic [7:0] data_out,
    output logic       k_out,
    output logic       valid_out,
    output logic       disp_err,
    output logic       code_err
);

    logic running_disparity;
    
    // 6b/5b decoding
    function automatic logic [5:0] decode_6b5b(input logic [5:0] code, output logic is_k);
        logic [5:0] result;
        is_k = 1'b0;
        case(code)
            6'b011000, 6'b100111: result = {1'b0, 5'h00};
            6'b100010, 6'b011101: result = {1'b0, 5'h01};
            6'b010010, 6'b101101: result = {1'b0, 5'h02};
            6'b110001: result = {1'b0, 5'h03};
            6'b001010, 6'b110101: result = {1'b0, 5'h04};
            6'b101001: result = {1'b0, 5'h05};
            6'b011001: result = {1'b0, 5'h06};
            6'b000111, 6'b111000: result = {1'b0, 5'h07};
            6'b000110, 6'b111001: result = {1'b0, 5'h08};
            6'b100101: result = {1'b0, 5'h09};
            6'b010101: result = {1'b0, 5'h0A};
            6'b110100: result = {1'b0, 5'h0B};
            6'b001101: result = {1'b0, 5'h0C};
            6'b101100: result = {1'b0, 5'h0D};
            6'b011100: result = {1'b0, 5'h0E};
            6'b101000, 6'b010111: result = {1'b0, 5'h0F};
            6'b100100, 6'b011011: result = {1'b0, 5'h10};
            6'b100011: result = {1'b0, 5'h11};
            6'b010011: result = {1'b0, 5'h12};
            6'b110010: result = {1'b0, 5'h13};
            6'b001011: result = {1'b0, 5'h14};
            6'b101010: result = {1'b0, 5'h15};
            6'b011010: result = {1'b0, 5'h16};
            6'b000101, 6'b111010: result = {1'b0, 5'h17};
            6'b001100, 6'b110011: result = {1'b0, 5'h18};
            6'b100110: result = {1'b0, 5'h19};
            6'b010110: result = {1'b0, 5'h1A};
            6'b001001, 6'b110110: result = {1'b0, 5'h1B};
            6'b001110: result = {1'b0, 5'h1C};
            6'b010001, 6'b101110: result = {1'b0, 5'h1D};
            6'b100001, 6'b011110: result = {1'b0, 5'h1E};
            6'b010100, 6'b101011: result = {1'b0, 5'h1F};
            default: result = {1'b1, 5'h00}; // Error
        endcase
        return result;
    endfunction
    
    // 4b/3b decoding
    function automatic logic [3:0] decode_4b3b(input logic [3:0] code);
        logic [3:0] result;
        case(code)
            4'b0100, 4'b1011: result = {1'b0, 3'h0};
            4'b1001: result = {1'b0, 3'h1};
            4'b0101: result = {1'b0, 3'h2};
            4'b0011, 4'b1100: result = {1'b0, 3'h3};
            4'b0010, 4'b1101: result = {1'b0, 3'h4};
            4'b1010: result = {1'b0, 3'h5};
            4'b0110: result = {1'b0, 3'h6};
            4'b0001, 4'b1110: result = {1'b0, 3'h7};
            default: result = {1'b1, 3'h0}; // Error
        endcase
        return result;
    endfunction
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            running_disparity <= 1'b0;
            data_out <= 8'h0;
            k_out <= 1'b0;
            valid_out <= 1'b0;
            disp_err <= 1'b0;
            code_err <= 1'b0;
        end else if (valid_in) begin
            logic [5:0] decoded_5b;
            logic [3:0] decoded_3b;
            logic is_k;
            int ones = $countones(data_in);
            
            decoded_5b = decode_6b5b(data_in[5:0], is_k);
            decoded_3b = decode_4b3b(data_in[9:6]);
            
            data_out <= {decoded_3b[2:0], decoded_5b[4:0]};
            k_out <= is_k;
            valid_out <= 1'b1;
            
            code_err <= decoded_5b[5] | decoded_3b[3];
            disp_err <= (running_disparity && ones > 5) || (!running_disparity && ones < 5);
            
            running_disparity <= (ones > 5) ? 1'b1 : 1'b0;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule
