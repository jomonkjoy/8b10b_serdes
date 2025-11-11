//==============================================================================
// Serializer with DDR output (5:1 SERDES + DDR = 10:1 overall)
//==============================================================================
module serializer_10b_ddr (
    input  logic        clk_byte,      // Byte clock (parallel data rate)
    input  logic        clk_bit,       // Bit clock (5x byte clock)
    input  logic        rst,
    input  logic [9:0]  data_parallel,
    output logic        data_serial
);

    logic [4:0] shift_reg;
    logic [2:0] bit_count;
    logic       data_odd, data_even;
    logic [9:0] data_latched;
    logic       load_pulse;
    logic       clk_bit_n;
    
    assign clk_bit_n = ~clk_bit;
    
    // Latch input data on byte clock
    always_ff @(posedge clk_byte or posedge rst) begin
        if (rst) begin
            data_latched <= 10'h0;
        end else begin
            data_latched <= data_parallel;
        end
    end
    
    // Generate load pulse synchronized to bit clock
    logic clk_byte_sync1, clk_byte_sync2, clk_byte_sync3;
    always_ff @(posedge clk_bit or posedge rst) begin
        if (rst) begin
            clk_byte_sync1 <= 1'b0;
            clk_byte_sync2 <= 1'b0;
            clk_byte_sync3 <= 1'b0;
            load_pulse <= 1'b0;
        end else begin
            clk_byte_sync1 <= clk_byte;
            clk_byte_sync2 <= clk_byte_sync1;
            clk_byte_sync3 <= clk_byte_sync2;
            load_pulse <= clk_byte_sync2 && !clk_byte_sync3;
        end
    end
    
    // 5-bit shift register running at bit clock
    always_ff @(posedge clk_bit or posedge rst) begin
        if (rst) begin
            shift_reg <= 5'h0;
            bit_count <= 3'h0;
            data_odd <= 1'b0;
            data_even <= 1'b0;
        end else begin
            if (load_pulse) begin
                // Load new data: bits [1,3,5,7,9] for odd, [0,2,4,6,8] for even
                shift_reg <= {data_latched[9], data_latched[7], data_latched[5], 
                             data_latched[3], data_latched[1]};
                bit_count <= 3'h0;
            end else begin
                // Shift out data
                shift_reg <= {1'b0, shift_reg[4:1]};
                if (bit_count < 3'd4)
                    bit_count <= bit_count + 1'b1;
            end
            
            // Output selection based on bit count
            case (bit_count)
                3'h0: begin
                    data_odd <= shift_reg[0];
                    data_even <= data_latched[0];
                end
                3'h1: begin
                    data_odd <= shift_reg[0];
                    data_even <= data_latched[2];
                end
                3'h2: begin
                    data_odd <= shift_reg[0];
                    data_even <= data_latched[4];
                end
                3'h3: begin
                    data_odd <= shift_reg[0];
                    data_even <= data_latched[6];
                end
                3'h4: begin
                    data_odd <= shift_reg[0];
                    data_even <= data_latched[8];
                end
                default: begin
                    data_odd <= 1'b0;
                    data_even <= 1'b0;
                end
            endcase
        end
    end
    
    // ODDR primitive for DDR output
    ODDR #(
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT(1'b0),
        .SRTYPE("SYNC")
    ) oddr_inst (
        .Q(data_serial),
        .C(clk_bit),
        .CE(1'b1),
        .D1(data_odd),   // Rising edge data
        .D2(data_even),  // Falling edge data
        .R(rst),
        .S(1'b0)
    );

endmodule
