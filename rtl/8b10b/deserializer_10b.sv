// Deserializer using ISERDESE2
module deserializer_10b (
    input  logic        clk_div,      // Parallel clock
    input  logic        clk_ser,      // Serial clock
    input  logic        rst,
    input  logic        data_serial,
    output logic [9:0]  data_parallel,
    output logic        valid
);

    logic [7:0] data_master;
    logic [1:0] data_slave;
    logic cascade_do, cascade_to;
    
    // Master ISERDESE2
    ISERDESE2 #(
        .DATA_RATE("DDR"),
        .DATA_WIDTH(10),
        .INTERFACE_TYPE("NETWORKING"),
        .IOBDELAY("NONE"),
        .NUM_CE(1),
        .SERDES_MODE("MASTER")
    ) iserdese2_master (
        .Q1(data_master[0]),
        .Q2(data_master[1]),
        .Q3(data_master[2]),
        .Q4(data_master[3]),
        .Q5(data_master[4]),
        .Q6(data_master[5]),
        .Q7(data_master[6]),
        .Q8(data_master[7]),
        .SHIFTOUT1(cascade_do),
        .SHIFTOUT2(cascade_to),
        .BITSLIP(1'b0),
        .CE1(1'b1),
        .CE2(1'b1),
        .CLK(clk_ser),
        .CLKB(~clk_ser),
        .CLKDIV(clk_div),
        .CLKDIVP(1'b0),
        .D(data_serial),
        .DDLY(1'b0),
        .RST(rst),
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0),
        .DYNCLKDIVSEL(1'b0),
        .DYNCLKSEL(1'b0),
        .OFB(1'b0),
        .OCLK(1'b0),
        .OCLKB(1'b0),
        .O()
    );
    
    // Slave ISERDESE2
    ISERDESE2 #(
        .DATA_RATE("DDR"),
        .DATA_WIDTH(10),
        .INTERFACE_TYPE("NETWORKING"),
        .IOBDELAY("NONE"),
        .NUM_CE(1),
        .SERDES_MODE("SLAVE")
    ) iserdese2_slave (
        .Q1(),
        .Q2(),
        .Q3(data_slave[0]),
        .Q4(data_slave[1]),
        .Q5(),
        .Q6(),
        .Q7(),
        .Q8(),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .BITSLIP(1'b0),
        .CE1(1'b1),
        .CE2(1'b1),
        .CLK(clk_ser),
        .CLKB(~clk_ser),
        .CLKDIV(clk_div),
        .CLKDIVP(1'b0),
        .D(1'b0),
        .DDLY(1'b0),
        .RST(rst),
        .SHIFTIN1(cascade_do),
        .SHIFTIN2(cascade_to),
        .DYNCLKDIVSEL(1'b0),
        .DYNCLKSEL(1'b0),
        .OFB(1'b0),
        .OCLK(1'b0),
        .OCLKB(1'b0),
        .O()
    );
    
    always_ff @(posedge clk_div or posedge rst) begin
        if (rst) begin
            data_parallel <= 10'h0;
            valid <= 1'b0;
        end else begin
            data_parallel <= {data_slave, data_master};
            valid <= 1'b1;
        end
    end

endmodule
