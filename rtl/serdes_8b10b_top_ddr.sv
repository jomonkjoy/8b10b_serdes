// Top-level module with IDDR/ODDR for clock reduction
// This implementation uses DDR to halve the serial clock requirement
// For 1 Gbps line rate: byte_clk = 100 MHz, bit_clk = 500 MHz (instead of 1 GHz)

module serdes_8b10b_top_ddr (
    // Clock inputs
    input  logic       clk_byte,      // Byte clock (e.g., 100 MHz for 1 Gbps)
    input  logic       clk_bit,       // Bit clock = 5x byte clock (e.g., 500 MHz)
    input  logic       rst_n,
    
    // Transmit interface
    input  logic [7:0] tx_data,
    input  logic       tx_k,
    input  logic       tx_valid,
    
    // Serial differential outputs (connect to OBUFDS)
    output logic       serial_out_p,
    output logic       serial_out_n,
    
    // Serial differential inputs (connect to IBUFDS)
    input  logic       serial_in_p,
    input  logic       serial_in_n,
    
    // Receive interface
    output logic [7:0] rx_data,
    output logic       rx_k,
    output logic       rx_valid,
    output logic       rx_disp_err,
    output logic       rx_code_err,
    
    // Status
    output logic       tx_ready,
    output logic       link_ready
);

    // Internal signals
    logic [9:0] encoded_data;
    logic       encoded_valid;
    logic [9:0] deserialized_data;
    logic       deserialized_valid;
    logic       rst;
    logic       serial_out_int;
    logic       serial_in_int;
    
    // Clock and reset
    assign rst = ~rst_n;
    assign tx_ready = rst_n;
    
    // Link ready after seeing valid data
    logic [7:0] valid_count;
    always_ff @(posedge clk_byte or negedge rst_n) begin
        if (!rst_n) begin
            valid_count <= 8'h0;
            link_ready <= 1'b0;
        end else begin
            if (rx_valid && !rx_code_err) begin
                if (valid_count < 8'hFF)
                    valid_count <= valid_count + 1'b1;
                if (valid_count > 8'h10)
                    link_ready <= 1'b1;
            end else if (rx_code_err) begin
                valid_count <= 8'h0;
                link_ready <= 1'b0;
            end
        end
    end
    
    //==========================================================================
    // TRANSMIT PATH
    //==========================================================================
    
    // 8b/10b Encoder
    encoder_8b10b encoder (
        .clk(clk_byte),
        .rst_n(rst_n),
        .data_in(tx_data),
        .k_in(tx_k),
        .data_out(encoded_data),
        .valid_out(encoded_valid)
    );
    
    // Serializer with DDR output stage
    serializer_10b_ddr tx_serializer (
        .clk_byte(clk_byte),
        .clk_bit(clk_bit),
        .rst(rst),
        .data_parallel(encoded_data),
        .data_serial(serial_out_int)
    );
    
    // Differential output buffer
    OBUFDS obufds_inst (
        .I(serial_out_int),
        .O(serial_out_p),
        .OB(serial_out_n)
    );
    
    //==========================================================================
    // RECEIVE PATH
    //==========================================================================
    
    // Differential input buffer
    IBUFDS ibufds_inst (
        .I(serial_in_p),
        .IB(serial_in_n),
        .O(serial_in_int)
    );
    
    // Deserializer with DDR input stage
    deserializer_10b_ddr rx_deserializer (
        .clk_byte(clk_byte),
        .clk_bit(clk_bit),
        .rst(rst),
        .data_serial(serial_in_int),
        .data_parallel(deserialized_data),
        .valid(deserialized_valid)
    );
    
    // 8b/10b Decoder
    decoder_8b10b decoder (
        .clk(clk_byte),
        .rst_n(rst_n),
        .data_in(deserialized_data),
        .valid_in(deserialized_valid),
        .data_out(rx_data),
        .k_out(rx_k),
        .valid_out(rx_valid),
        .disp_err(rx_disp_err),
        .code_err(rx_code_err)
    );

endmodule
