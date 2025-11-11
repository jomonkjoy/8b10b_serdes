//==============================================================================
// Complete system with clock generation
//==============================================================================
module serdes_8b10b_system (
    // Clock and reset
    input  logic       clk_ref_100mhz,
    input  logic       sys_rst_n,
    
    // Transmit interface
    input  logic [7:0] tx_data,
    input  logic       tx_k,
    input  logic       tx_valid,
    
    // Serial I/O
    output logic       serial_tx_p,
    output logic       serial_tx_n,
    input  logic       serial_rx_p,
    input  logic       serial_rx_n,
    
    // Receive interface
    output logic [7:0] rx_data,
    output logic       rx_k,
    output logic       rx_valid,
    output logic       rx_disp_err,
    output logic       rx_code_err,
    
    // Status
    output logic       tx_ready,
    output logic       link_ready,
    output logic       clk_locked
);

    logic clk_byte, clk_bit;
    logic rst_n;
    
    // Clock generation
    serdes_8b10b_clocking clock_gen (
        .clk_ref(clk_ref_100mhz),
        .rst_in(~sys_rst_n),
        .clk_byte(clk_byte),
        .clk_bit(clk_bit),
        .rst_n(rst_n),
        .locked(clk_locked)
    );
    
    // SerDes core
    serdes_8b10b_top_ddr serdes_core (
        .clk_byte(clk_byte),
        .clk_bit(clk_bit),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_k(tx_k),
        .tx_valid(tx_valid),
        .serial_out_p(serial_tx_p),
        .serial_out_n(serial_tx_n),
        .serial_in_p(serial_rx_p),
        .serial_in_n(serial_rx_n),
        .rx_data(rx_data),
        .rx_k(rx_k),
        .rx_valid(rx_valid),
        .rx_disp_err(rx_disp_err),
        .rx_code_err(rx_code_err),
        .tx_ready(tx_ready),
        .link_ready(link_ready)
    );

endmodule
