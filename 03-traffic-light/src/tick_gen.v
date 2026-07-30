// =========================================================================
// tick_gen.v
//
// Generates a single-cycle "tick" pulse every DIVISOR clock cycles. Used
// to slow a fast system clock (e.g. 50MHz on the DE2-115, 125MHz on
// Zybo) down to a human-visible rate (e.g. once per second) without the
// rest of the design needing to know or care what the actual clock
// frequency is.
//
// Example: at 50MHz, DIVISOR = 50_000_000 gives a 1-tick-per-second pulse.
// In simulation, override DIVISOR to something tiny (e.g. 4) so tests
// run fast.
// =========================================================================
module tick_gen #(
    parameter DIVISOR = 50_000_000
) (
    input  wire clk,
    input  wire rst,
    output reg  tick     // 1-cycle pulse every DIVISOR clock cycles
);

    localparam WIDTH = $clog2(DIVISOR);
    reg [WIDTH-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            tick    <= 1'b0;
        /* verilator lint_off WIDTHEXPAND */
        end else if (counter == DIVISOR - 1) begin
        /* verilator lint_on WIDTHEXPAND */
            counter <= 0;
            tick    <= 1'b1;
        end else begin
            counter <= counter + 1;
            tick    <= 1'b0;
        end
    end

endmodule
