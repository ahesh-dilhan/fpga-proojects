// =========================================================================
// btn_led_top.v
//
// Top-level design for the Zybo Z7. Demonstrates two common button->LED
// patterns:
//
//   1. btn0 -> led0  : "follow" mode. LED is lit only while button is held.
//   2. btn1 -> led1  : "toggle" mode. Each press flips the LED state.
//                      This needs edge detection (rising-edge detector),
//                      not just a wire connection - a good intro to
//                      sequential logic / simple FSM thinking.
// =========================================================================
module btn_led_top #(
    parameter DEBOUNCE_CYCLES = 250000  // ~2ms at 125MHz. Override to a small
                                         // value (e.g. 4) in simulation only,
                                         // so the testbench doesn't need to
                                         // wait 2ms of simulated time per test.
) (
    input  wire clk,     // 125 MHz on Zybo Z7
    input  wire rst,     // active-high reset (wire to a button/switch, or tie 0)
    input  wire btn0,
    input  wire btn1,
    output wire led0,
    output wire led1
);

    // ---- Debounce both raw button inputs ----
    wire btn0_clean, btn1_clean;

    debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_debounce_btn0 (
        .clk(clk), .rst(rst), .btn_in(btn0), .btn_out(btn0_clean)
    );

    debounce #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_debounce_btn1 (
        .clk(clk), .rst(rst), .btn_in(btn1), .btn_out(btn1_clean)
    );

    // ---- Pattern 1: follow mode ----
    assign led0 = btn0_clean;

    // ---- Pattern 2: toggle mode via rising-edge detection ----
    reg btn1_clean_d;       // 1-cycle delayed version, for edge detection
    reg led1_reg;

    always @(posedge clk) begin
        if (rst) begin
            btn1_clean_d <= 1'b0;
            led1_reg     <= 1'b0;
        end else begin
            btn1_clean_d <= btn1_clean;
            // rising edge = clean signal is 1 now, was 0 last cycle
            if (btn1_clean && !btn1_clean_d) begin
                led1_reg <= ~led1_reg;
            end
        end
    end

    assign led1 = led1_reg;

endmodule
