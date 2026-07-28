// =========================================================================
// debounce.v
//
// Classic counter-based button debouncer.
//
// Why it's needed: mechanical buttons "bounce" - when pressed, the signal
// doesn't go cleanly from 0 to 1, it chatters between 0 and 1 rapidly for
// a few milliseconds before settling. Without debouncing, your FSM/counter
// logic would see many false button presses instead of one clean press.
//
// How it works: we only accept a change in the button state after it has
// been STABLE for DEBOUNCE_CYCLES clock cycles in a row. If it flickers,
// the counter keeps resetting and never reaches the threshold.
// =========================================================================
module debounce #(
    parameter DEBOUNCE_CYCLES = 200000  // ~2ms at 100MHz. Tune per clock freq.
) (
    input  wire clk,
    input  wire rst,          // synchronous, active-high
    input  wire btn_in,       // raw, noisy button input
    output reg  btn_out       // clean, debounced output
);

    reg [$clog2(DEBOUNCE_CYCLES):0] counter;
    reg btn_sync_0, btn_sync_1;   // 2-stage synchronizer for the async input

    // Stage 1: synchronize the asynchronous button input into our clock
    // domain. This is a separate concern from debouncing - it prevents
    // metastability, since the button signal did not originate from our
    // clock and can change at any time relative to our clock edge.
    always @(posedge clk) begin
        if (rst) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Stage 2: debounce logic. Count how long the synchronized signal has
    // been different from our current stable output. Only accept it once
    // it has held steady for DEBOUNCE_CYCLES.
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            btn_out <= 1'b0;
        end else if (btn_sync_1 != btn_out) begin
            if (counter >= DEBOUNCE_CYCLES - 1) begin
                btn_out <= btn_sync_1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
        end else begin
            counter <= 0;  // signal matches output, reset counter
        end
    end

endmodule
