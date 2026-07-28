// =========================================================================
// uart_rx.v
//
// UART receiver. Matches uart_tx's 8N1 frame format.
//
// Waits for the start bit (falling edge on rx_serial, which idles high),
// then samples each bit in the MIDDLE of its bit period (not right at the
// edge) - this gives maximum tolerance to slight clock/timing mismatch
// between transmitter and receiver, which is the whole reason UART needs
// a defined baud rate in the first place.
//
// rx_done pulses for 1 clock cycle when a complete byte has been received,
// with the byte available on rx_data at that same moment (and held until
// the next byte arrives).
// =========================================================================
module uart_rx #(
    parameter CLKS_PER_BIT = 1085
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx_serial,
    output reg  [7:0] rx_data,
    output reg        rx_done      // 1-cycle pulse when a byte is received
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_data_shift;

    // 2-stage synchronizer, same reasoning as in debounce.v - rx_serial is
    // asynchronous to our clock domain (it comes from another device/wire).
    reg rx_sync_0, rx_sync_1;
    always @(posedge clk) begin
        rx_sync_0 <= rx_serial;
        rx_sync_1 <= rx_sync_0;
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            rx_data       <= 8'h00;
            rx_data_shift <= 8'h00;
            rx_done       <= 1'b0;
        end else begin
            rx_done <= 1'b0;  // default; only pulses in STOP state below

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_sync_1 == 1'b0) begin  // falling edge = start bit
                        state <= START;
                    end
                end

                START: begin
                    // wait until the middle of the start bit to confirm it's
                    // real (not just a glitch) before committing to receive
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_sync_1 == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE;  // was a glitch, abort
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    // sample once per bit period, at the midpoint
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_data_shift[bit_index] <= rx_sync_1;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    // wait out the stop bit period, then latch the byte
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_data   <= rx_data_shift;
                        rx_done   <= 1'b1;  // 1-cycle pulse
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
