// =========================================================================
// tb_traffic_light_top.v
//
// Testbench for traffic_light_top. Uses tiny DIVISOR/GREEN_TICKS/
// YELLOW_TICKS overrides so simulation runs fast, and checks:
//   1. The safety invariant: NS and EW can never both be non-red at once
//   2. The state sequence follows NS_GREEN -> NS_YELLOW -> EW_GREEN ->
//      EW_YELLOW -> NS_GREEN ... in order
// =========================================================================
`timescale 1ns / 1ps

module tb_traffic_light_top;

    reg clk, rst;
    wire ns_red, ns_yellow, ns_green;
    wire ew_red, ew_yellow, ew_green;

    // Small values for fast simulation: divisor=2 means a tick every 2
    // clock cycles; green=3 ticks, yellow=2 ticks.
    traffic_light_top #(
        .DIVISOR(2), .GREEN_TICKS(3), .YELLOW_TICKS(2)
    ) dut (
        .clk(clk), .rst(rst),
        .ns_red(ns_red), .ns_yellow(ns_yellow), .ns_green(ns_green),
        .ew_red(ew_red), .ew_yellow(ew_yellow), .ew_green(ew_green)
    );

    initial clk = 0;
    always #4 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_traffic_light_top);
    end

    integer errors = 0;
    integer i;

    // ---- Safety checker: runs continuously throughout the whole test ----
    // NS and EW must never both show a non-red light at the same time.
    always @(posedge clk) begin
        if (!rst) begin
            if ((ns_yellow || ns_green) && (ew_yellow || ew_green)) begin
                $display("SAFETY FAIL at T=%0t: both directions non-red simultaneously!", $time);
                errors = errors + 1;
            end
        end
    end

    // Helper: decode current visible state as a string for readable logs
    function [8*10:1] state_name;
        input dummy;
        begin
            if (ns_green)       state_name = "NS_GREEN";
            else if (ns_yellow) state_name = "NS_YELLOW";
            else if (ew_green)  state_name = "EW_GREEN";
            else if (ew_yellow) state_name = "EW_YELLOW";
            else                state_name = "ALL_RED?";  // shouldn't happen
        end
    endfunction

    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        // ---- Check initial state ----
        @(posedge clk);
        if (!ns_green) begin
            $display("FAIL: expected to start in NS_GREEN");
            errors = errors + 1;
        end else begin
            $display("PASS: starts in NS_GREEN");
        end

        // ---- Walk through 2 full cycles of the FSM, logging transitions ----
        for (i = 0; i < 2; i = i + 1) begin
            $display("--- Cycle %0d ---", i);

            wait (ns_yellow);
            $display("T=%0t: PASS: transitioned to NS_YELLOW", $time);

            wait (ew_green);
            $display("T=%0t: PASS: transitioned to EW_GREEN", $time);

            wait (ew_yellow);
            $display("T=%0t: PASS: transitioned to EW_YELLOW", $time);

            wait (ns_green);
            $display("T=%0t: PASS: transitioned back to NS_GREEN", $time);
        end

        if (errors == 0)
            $display("ALL TESTS PASSED (including continuous safety check)");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

    // Safety net: if the FSM gets stuck and never reaches an expected
    // state, don't let the simulation hang forever - time out instead.
    initial begin
        #10000;
        $display("TIMEOUT: simulation did not finish in time - FSM may be stuck");
        $finish;
    end

endmodule
