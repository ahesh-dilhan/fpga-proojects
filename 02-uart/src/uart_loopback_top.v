// =========================================================================
// uart_loopback_top.v
//
// Top-level design for the Zybo Z7. Each press of btn0 transmits an
// incrementing byte (0x00, 0x01, 0x02, ...) out over UART on Pmod JA
// pin 0. The receiver listens on Pmod JA pin 1 and displays the lower
// 4 bits of whatever byte it receives on the 4 onboard LEDs.
//
// To test on real hardware: connect a jumper wire from JA pin 1 to JA
// pin 2 (i.e. ja[0] to ja[1]) on the Pmod header. This loops the
// transmitted signal directly back into the receiver, so you're
// exercising the real electrical TX/RX path, not just internal logic.
//
// Expected behavior: press btn0 repeatedly, watch the 4 LEDs count up
// in binary (0000, 0001, 0010, 0011, ...) - each press transmits the
// next byte, which loops back through the wire and gets received and
// displayed almost instantly (well under 1ms at 115200 baud).
// =========================================================================
module uart_loopback_top #(
    parameter CLKS_PER_BIT = 1085  // 125MHz / 115200 baud
) (
    input  wire clk,
    input  wire rst,
    input  wire btn0,
    input  wire uart_rx_pin,   // ja[1] - wire this to uart_tx_pin externally
    output wire uart_tx_pin,   // ja[0]
    output wire [3:0] led
);

    // ---- Debounce the button ----
    wire btn0_clean;
    debounce #(.DEBOUNCE_CYCLES(250000)) u_debounce (
        .clk(clk), .rst(rst), .btn_in(btn0), .btn_out(btn0_clean)
    );

    // Edge-detect the debounced button to get a single-cycle "start" pulse
    reg btn0_clean_d;
    wire btn0_pressed = btn0_clean && !btn0_clean_d;
    always @(posedge clk) begin
        if (rst) btn0_clean_d <= 1'b0;
        else     btn0_clean_d <= btn0_clean;
    end

    // ---- Byte counter: increments each time we send a byte ----
    reg [7:0] tx_byte;
    always @(posedge clk) begin
        if (rst) tx_byte <= 8'h00;
        else if (btn0_pressed) tx_byte <= tx_byte + 1;
        // NOTE: tx_byte increments the cycle AFTER btn0_pressed, so the
        // value latched into uart_tx below is the value from BEFORE this
        // press. That's fine - it just means the very first press sends
        // 0x00, second press sends 0x01, etc. Still demonstrates the flow.
    end

    // ---- UART transmitter ----
    wire tx_busy;
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_tx (
        .clk(clk), .rst(rst),
        .tx_start(btn0_pressed),
        .tx_data(tx_byte),
        .tx_serial(uart_tx_pin),
        .tx_busy(tx_busy),
        .tx_done()  // unused here
    );

    // ---- UART receiver ----
    wire [7:0] rx_data;
    wire rx_done;
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_rx (
        .clk(clk), .rst(rst),
        .rx_serial(uart_rx_pin),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    // ---- Latch the last received byte's lower nibble onto the LEDs ----
    reg [3:0] led_reg;
    always @(posedge clk) begin
        if (rst) led_reg <= 4'h0;
        else if (rx_done) led_reg <= rx_data[3:0];
    end
    assign led = led_reg;

endmodule
