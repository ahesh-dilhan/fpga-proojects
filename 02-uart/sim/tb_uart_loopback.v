// =========================================================================
// tb_uart_loopback.v
//
// Testbench for uart_tx + uart_rx, connected directly (tx_serial wired to
// rx_serial) to simulate the loopback jumper wire used on real hardware.
// Uses a small CLKS_PER_BIT so simulation runs fast.
// =========================================================================
`timescale 1ns / 1ps

module tb_uart_loopback;

    localparam CLKS_PER_BIT = 4;  // tiny value for fast simulation

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_serial;
    wire tx_busy;
    wire tx_done;

    wire [7:0] rx_data;
    wire rx_done;

    // The "loopback wire": tx output directly drives rx input
    wire serial_line = tx_serial;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut_tx (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx_serial(tx_serial), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut_rx (
        .clk(clk), .rst(rst),
        .rx_serial(serial_line),
        .rx_data(rx_data), .rx_done(rx_done)
    );

    initial clk = 0;
    always #4 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart_loopback);
    end

    integer errors = 0;

    // Helper task: send one byte and wait for it to fully transmit
    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            tx_data  = data;
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            // wait for tx to finish (tx_busy goes low)
            wait (tx_busy == 0);
        end
    endtask

    // Helper task: wait for rx_done pulse and check the received byte
    task check_received(input [7:0] expected);
        begin
            wait (rx_done == 1);
            @(posedge clk);  // let rx_data settle
            if (rx_data !== expected) begin
                $display("FAIL: expected 0x%02h, got 0x%02h", expected, rx_data);
                errors = errors + 1;
            end else begin
                $display("PASS: received 0x%02h correctly", rx_data);
            end
        end
    endtask

    initial begin
        rst      = 1;
        tx_start = 0;
        tx_data  = 8'h00;
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        // Test several bytes, including edge cases (all zeros, all ones,
        // alternating pattern)
        $display("T=%0t: Sending 0x00", $time);
        fork
            send_byte(8'h00);
            check_received(8'h00);
        join

        repeat (10) @(posedge clk);

        $display("T=%0t: Sending 0xFF", $time);
        fork
            send_byte(8'hFF);
            check_received(8'hFF);
        join

        repeat (10) @(posedge clk);

        $display("T=%0t: Sending 0xA5 (alternating bits)", $time);
        fork
            send_byte(8'hA5);
            check_received(8'hA5);
        join

        repeat (10) @(posedge clk);

        $display("T=%0t: Sending 0x55 (alternating bits, inverted)", $time);
        fork
            send_byte(8'h55);
            check_received(8'h55);
        join

        repeat (10) @(posedge clk);

        if (errors == 0)
            $display("T=%0t: ALL TESTS PASSED", $time);
        else
            $display("T=%0t: %0d TEST(S) FAILED", $time, errors);

        $finish;
    end

endmodule
