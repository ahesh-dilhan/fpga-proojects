// =========================================================================
// tb_btn_led_top.v
//
// Testbench for btn_led_top. Uses a small DEBOUNCE_CYCLES override so
// simulation runs fast. Drives both clean presses and deliberately
// "bouncy" (glitchy) presses to prove the debouncer is working.
//
// See docs/simulate.md for the exact simulation command to run.
// =========================================================================
`timescale 1ns / 1ps

module tb_btn_led_top;

    reg clk;
    reg rst;
    reg btn0;
    reg btn1;
    wire led0;
    wire led1;

    // Small debounce window for fast sim: 4 clock cycles instead of 250000
    btn_led_top #(.DEBOUNCE_CYCLES(4)) dut (
        .clk(clk), .rst(rst),
        .btn0(btn0), .btn1(btn1),
        .led0(led0), .led1(led1)
    );

    // 125MHz-equivalent clock (period doesn't matter much in sim, use 8ns)
    initial clk = 0;
    always #4 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_btn_led_top);
    end

    initial begin
        // ---- Reset ----
        rst  = 1;
        btn0 = 0;
        btn1 = 0;
        repeat (5) @(posedge clk);
        rst  = 0;

        // ---- Test 1: clean btn0 press (follow mode) ----
        $display("T=%0t: Test 1 - clean btn0 press, expect led0 to follow", $time);
        @(posedge clk);
        btn0 = 1;
        repeat (10) @(posedge clk);
        if (led0 !== 1) $display("FAIL: led0 should be 1 after clean press");
        else $display("PASS: led0 followed btn0 press");

        btn0 = 0;
        repeat (10) @(posedge clk);
        if (led0 !== 0) $display("FAIL: led0 should be 0 after release");
        else $display("PASS: led0 followed btn0 release");

        // ---- Test 2: bouncy btn0 press - debouncer should filter it ----
        $display("T=%0t: Test 2 - bouncy btn0 press, expect led0 stays 0 until settled", $time);
        btn0 = 1; @(posedge clk);
        btn0 = 0; @(posedge clk);
        btn0 = 1; @(posedge clk);
        btn0 = 0; @(posedge clk);
        // less than DEBOUNCE_CYCLES=4 stable cycles so far - should still be 0
        if (led0 !== 0) $display("FAIL: led0 should still be 0 during bounce");
        else $display("PASS: led0 correctly ignored bounce");
        btn0 = 1;  // now hold stable
        repeat (10) @(posedge clk);
        if (led0 !== 1) $display("FAIL: led0 should settle to 1 after bounce stops");
        else $display("PASS: led0 settled correctly after bounce");
        btn0 = 0;
        repeat (10) @(posedge clk);

        // ---- Test 3: btn1 toggle mode ----
        $display("T=%0t: Test 3 - btn1 toggle mode", $time);
        if (led1 !== 0) $display("FAIL: led1 should start at 0");

        btn1 = 1; repeat (10) @(posedge clk);
        btn1 = 0; repeat (10) @(posedge clk);
        if (led1 !== 1) $display("FAIL: led1 should be 1 after first toggle press");
        else $display("PASS: led1 toggled to 1 on first press");

        btn1 = 1; repeat (10) @(posedge clk);
        btn1 = 0; repeat (10) @(posedge clk);
        if (led1 !== 0) $display("FAIL: led1 should be 0 after second toggle press");
        else $display("PASS: led1 toggled back to 0 on second press");

        $display("T=%0t: All tests complete", $time);
        $finish;
    end

endmodule
