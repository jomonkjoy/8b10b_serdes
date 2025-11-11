//==============================================================================
// Deserializer with DDR input and Bit-slip logic (DDR + 1:5 SERDES = 1:10 overall)
//==============================================================================
module deserializer_10b_ddr (
    input  logic        clk_byte,
    input  logic        clk_bit,
    input  logic        rst,
    input  logic        data_serial,
    input  logic        bitslip,         // Bitslip command from byte clock domain
    output logic [9:0]  data_parallel,
    output logic        valid,
    output logic        aligned          // Indicates alignment has been achieved
);

    logic data_odd, data_even;
    logic [9:0] shift_reg;               // 10-bit shift register for bit-slip
    logic [2:0] bit_count;
    logic [9:0] assembled_data;
    logic [3:0] bitslip_offset;          // Current bit-slip offset (0-9)
    logic       bitslip_sync1, bitslip_sync2, bitslip_pulse;
    logic [9:0] rotated_data;
    
    // IDDR primitive for DDR input
    IDDR #(
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT_Q1(1'b0),
        .INIT_Q2(1'b0),
        .SRTYPE("SYNC")
    ) iddr_inst (
        .Q1(data_odd),   // Rising edge output
        .Q2(data_even),  // Falling edge output
        .C(clk_bit),
        .CE(1'b1),
        .D(data_serial),
        .R(rst),
        .S(1'b0)
    );
    
    // Synchronize bitslip command to bit clock domain
    always_ff @(posedge clk_bit or posedge rst) begin
        if (rst) begin
            bitslip_sync1 <= 1'b0;
            bitslip_sync2 <= 1'b0;
            bitslip_pulse <= 1'b0;
        end else begin
            bitslip_sync1 <= bitslip;
            bitslip_sync2 <= bitslip_sync1;
            bitslip_pulse <= bitslip_sync1 && !bitslip_sync2;  // Edge detect
        end
    end
    
    // 10-bit shift register with bit-slip capability
    always_ff @(posedge clk_bit or posedge rst) begin
        if (rst) begin
            shift_reg <= 10'h0;
            bit_count <= 3'h0;
            bitslip_offset <= 4'h0;
        end else begin
            // Shift in new data (2 bits per cycle from DDR)
            shift_reg <= {shift_reg[7:0], data_odd, data_even};
            
            // Handle bit-slip
            if (bitslip_pulse) begin
                if (bitslip_offset < 4'd9)
                    bitslip_offset <= bitslip_offset + 1'b1;
                else
                    bitslip_offset <= 4'h0;
            end
            
            // Count groups of 5 bit clock cycles (10 bits total)
            if (bit_count < 3'd4)
                bit_count <= bit_count + 1'b1;
            else
                bit_count <= 3'h0;
        end
    end
    
    // Barrel shifter for bit-slip adjustment
    always_comb begin
        case (bitslip_offset)
            4'd0:  rotated_data = shift_reg;
            4'd1:  rotated_data = {shift_reg[0], shift_reg[9:1]};
            4'd2:  rotated_data = {shift_reg[1:0], shift_reg[9:2]};
            4'd3:  rotated_data = {shift_reg[2:0], shift_reg[9:3]};
            4'd4:  rotated_data = {shift_reg[3:0], shift_reg[9:4]};
            4'd5:  rotated_data = {shift_reg[4:0], shift_reg[9:5]};
            4'd6:  rotated_data = {shift_reg[5:0], shift_reg[9:6]};
            4'd7:  rotated_data = {shift_reg[6:0], shift_reg[9:7]};
            4'd8:  rotated_data = {shift_reg[7:0], shift_reg[9:8]};
            4'd9:  rotated_data = {shift_reg[8:0], shift_reg[9]};
            default: rotated_data = shift_reg;
        endcase
    end
    
    // Capture aligned word
    logic assembled_valid;
    always_ff @(posedge clk_bit or posedge rst) begin
        if (rst) begin
            assembled_data <= 10'h0;
            assembled_valid <= 1'b0;
        end else begin
            if (bit_count == 3'd4) begin
                assembled_data <= rotated_data;
                assembled_valid <= 1'b1;
            end else begin
                assembled_valid <= 1'b0;
            end
        end
    end
    
    // Synchronize to byte clock domain
    logic valid_sync1, valid_sync2;
    logic [9:0] data_sync;
    always_ff @(posedge clk_byte or posedge rst) begin
        if (rst) begin
            data_parallel <= 10'h0;
            data_sync <= 10'h0;
            valid_sync1 <= 1'b0;
            valid_sync2 <= 1'b0;
            valid <= 1'b0;
        end else begin
            valid_sync1 <= assembled_valid;
            valid_sync2 <= valid_sync1;
            
            if (assembled_valid)
                data_sync <= assembled_data;
            
            if (valid_sync1 && !valid_sync2) begin
                data_parallel <= data_sync;
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end
    
    // Alignment indicator (simplified - could be enhanced with comma detection)
    logic [7:0] valid_count;
    always_ff @(posedge clk_byte or posedge rst) begin
        if (rst) begin
            valid_count <= 8'h0;
            aligned <= 1'b0;
        end else begin
            if (valid) begin
                if (valid_count < 8'hFF)
                    valid_count <= valid_count + 1'b1;
                if (valid_count > 8'h20)
                    aligned <= 1'b1;
            end else begin
                valid_count <= 8'h0;
                aligned <= 1'b0;
            end
        end
    end

endmodule
