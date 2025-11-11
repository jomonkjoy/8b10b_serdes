// Serializer using OSERDESE2
module serializer_10b (
    input  logic        clk_div,      // Parallel clock (e.g., 100 MHz)
    input  logic        clk_ser,      // Serial clock (e.g., 1 GHz)
    input  logic        rst,
    input  logic [9:0]  data_parallel,
    output logic        data_serial
);

    logic cascade_do, cascade_to;
    logic cascade_di, cascade_ti;
    
    // Master OSERDESE2 (outputs bits 0-7)
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),
        .SERDES_MODE("MASTER"),
        .TRISTATE_WIDTH(1)
    ) oserdese2_master (
        .OQ(data_serial),
        .OFB(),
        .TQ(),
        .TFB(),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .CLK(clk_ser),
        .CLKDIV(clk_div),
        .D1(data_parallel[0]),
        .D2(data_parallel[1]),
        .D3(data_parallel[2]),
        .D4(data_parallel[3]),
        .D5(data_parallel[4]),
        .D6(data_parallel[5]),
        .D7(data_parallel[6]),
        .D8(data_parallel[7]),
        .TCE(1'b0),
        .OCE(1'b1),
        .TBYTEIN(1'b0),
        .TBYTEOUT(),
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .SHIFTIN1(cascade_di),
        .SHIFTIN2(cascade_ti),
        .SHIFTOUT1(cascade_do),
        .SHIFTOUT2(cascade_to),
        .RST(rst)
    );
    
    // Slave OSERDESE2 (outputs bits 8-9)
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("SDR"),
        .DATA_WIDTH(10),
        .SERDES_MODE("SLAVE"),
        .TRISTATE_WIDTH(1)
    ) oserdese2_slave (
        .OQ(),
        .OFB(),
        .TQ(),
        .TFB(),
        .SHIFTOUT1(cascade_di),
        .SHIFTOUT2(cascade_ti),
        .CLK(clk_ser),
        .CLKDIV(clk_div),
        .D1(1'b0),
        .D2(1'b0),
        .D3(data_parallel[8]),
        .D4(data_parallel[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        .TCE(1'b0),
        .OCE(1'b1),
        .TBYTEIN(1'b0),
        .TBYTEOUT(),
        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .SHIFTIN1(cascade_do),
        .SHIFTIN2(cascade_to),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .RST(rst)
    );

endmodule
