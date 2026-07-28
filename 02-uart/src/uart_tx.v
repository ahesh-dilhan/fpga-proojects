// =========================================================================
// uart_tx.v
//
// UART transmitter. Standard 8N1 frame: 1 start bit (0), 8 data bits
// (LSB first), 1 stop bit (1).
//
// Usage: pulse tx_start high for one clock cycle while tx_data holds the
// byte you want to send. tx_busy stays high until the frame is fully sent.
// Don't start a new byte while tx_busy is high - wait for it to clear.
// =========================================================================
module uart_tx #(
    parameter CLKS_PER_BIT = 1085  // 125MHz / 115200 baud ~= 1085
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx_serial,
    output reg        tx_busy,
    output reg        tx_done      // 1-cycle pulse when a byte finishes sending
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_data_latched;

    always @(posedge clk) begin
        if (rst) begin
            state           <= IDLE;
            clk_count       <= 0;
            bit_index       <= 0;
            tx_serial       <= 1'b1;   // idle line is high
            tx_busy         <= 1'b0;
            tx_done         <= 1'b0;
            tx_data_latched <= 8'h00;
        end else begin
            tx_done <= 1'b0;  // default; only pulses in STOP state below

            case (state)
                IDLE: begin
                    tx_serial <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_busy         <= 1'b1;
                        tx_data_latched <= tx_data;  // capture data at start
                        state           <= START;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                START: begin
                    tx_serial <= 1'b0;  // start bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx_serial <= tx_data_latched[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_serial <= 1'b1;  // stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        tx_done   <= 1'b1;  // 1-cycle pulse
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
