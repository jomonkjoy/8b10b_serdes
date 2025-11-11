// Top-level module integrating everything
module serdes_8b10b_top (
    input  logic       clk_parallel,  // e.g., 100 MHz
    input  logic       clk_serial,    // e.g., 1 GHz
    input  logic       rst_n,
    input  logic [7:0] tx_data,
    input  logic       tx_k,
    output logic       serial_out,
    input  logic       serial_in,
    output logic [7:0] rx_data,
    output logic       rx_k,
    output logic       rx_valid,
    output logic       rx_disp_err,
    output logic       rx_code_err
);

    logic [9:0] encoded_data;
    logic       encoded_valid;
    logic [9:0] deserialized_data;
    logic       deserialized_valid;
    logic       rst;
    
    assign rst = ~rst_n;
    
    // Encoder
    encoder_8b10b encoder (
        .clk(clk_parallel),
        .rst_n(rst_n),
        .data_in(tx_data),
        .k_in(tx_k),
        .data_out(encoded_data),
        .valid_out(encoded_valid)
    );
    
    // Serializer
    serializer_10b serializer (
        .clk_div(clk_parallel),
        .clk_ser(clk_serial),
        .rst(rst),
        .data_parallel(encoded_data),
        .data_serial(serial_out)
    );
    
    // Deserializer
    deserializer_10b deserializer (
        .clk_div(clk_parallel),
        .clk_ser(clk_serial),
        .rst(rst),
        .data_serial(serial_in),
        .data_parallel(deserialized_data),
        .valid(deserialized_valid)
    );
    
    // Decoder
    decoder_8b10b decoder (
        .clk(clk_parallel),
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
