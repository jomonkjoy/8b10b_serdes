//==============================================================================
// Clock generation wrapper for synthesis
//==============================================================================
module serdes_8b10b_clocking (
    input  logic clk_ref,        // Reference clock input (e.g., 100 MHz)
    input  logic rst_in,
    output logic clk_byte,       // Byte clock output (100 MHz)
    output logic clk_bit,        // Bit clock output (500 MHz)
    output logic rst_n,
    output logic locked
);

    logic clk_fb;
    logic clk_byte_unbuf, clk_bit_unbuf;
    logic rst_mmcm;
    
    assign rst_mmcm = rst_in;
    
    // MMCM for clock generation
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(10.0),     // VCO = 100 MHz * 10 = 1000 MHz
        .CLKFBOUT_PHASE(0.0),
        .CLKIN1_PERIOD(10.0),       // 100 MHz input
        .CLKOUT0_DIVIDE_F(10.0),    // 1000/10 = 100 MHz (byte clock)
        .CLKOUT1_DIVIDE(2),         // 1000/2 = 500 MHz (bit clock)
        .CLKOUT0_PHASE(0.0),
        .CLKOUT1_PHASE(0.0),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .STARTUP_WAIT("FALSE")
    ) mmcm_inst (
        .CLKIN1(clk_ref),
        .CLKFBIN(clk_fb),
        .CLKFBOUT(clk_fb),
        .CLKOUT0(clk_byte_unbuf),
        .CLKOUT1(clk_bit_unbuf),
        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .LOCKED(locked),
        .PWRDWN(1'b0),
        .RST(rst_mmcm)
    );
    
    // Buffer output clocks
    BUFG bufg_byte (
        .I(clk_byte_unbuf),
        .O(clk_byte)
    );
    
    BUFG bufg_bit (
        .I(clk_bit_unbuf),
        .O(clk_bit)
    );
    
    // Generate synchronized reset
    logic [7:0] rst_shift;
    always_ff @(posedge clk_byte or negedge locked) begin
        if (!locked) begin
            rst_shift <= 8'hFF;
            rst_n <= 1'b0;
        end else begin
            rst_shift <= {rst_shift[6:0], 1'b0};
            rst_n <= (rst_shift == 8'h00);
        end
    end

endmodule
