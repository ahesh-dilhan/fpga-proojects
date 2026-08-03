// =========================================================================
// tb_sync_fifo.v
//
// Tests, in order:
//   1. Starts empty
//   2. Fill completely, verify full asserts at exactly the right point
//   3. Overflow protection: writing while full is silently ignored
//   4. Drain completely, verify data comes out in the same order it went
//      in (the entire point of a FIFO), and empty asserts at the right point
//   5. Underflow protection: reading while empty is silently ignored
//   6. Simultaneous read+write while partially full (the trickiest case -
//      exercises both pointers moving on the same clock edge)
// =========================================================================
`timescale 1ns / 1ps

module tb_sync_fifo;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 8;

    reg clk, rst;
    reg wr_en, rd_en;
    reg [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;
    wire full, empty;

    sync_fifo #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst(rst),
        .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    initial clk = 0;
    always #4 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    integer errors = 0;
    integer i;

    task check(input cond, input [800:1] msg);
        begin
            if (!cond) begin
                $display("FAIL: %0s", msg);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s", msg);
            end
        end
    endtask

    initial begin
        rst = 1; wr_en = 0; rd_en = 0; wr_data = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ---- Test 1: starts empty ----
        check(empty == 1 && full == 0, "starts empty, not full");

        // ---- Test 2: fill completely ----
        $display("--- Filling FIFO (writing %0d items) ---", DEPTH);
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            wr_en   = 1;
            wr_data = i;  // write values 0,1,2,...,DEPTH-1 in order
            @(posedge clk);
            #1;
            if (i < DEPTH - 1)
                check(full == 0, "not full before last write");
        end
        @(negedge clk);
        wr_en = 0;
        #1;
        check(full == 1, "full asserts after writing DEPTH items");

        // ---- Test 3: overflow protection ----
        @(negedge clk);
        wr_en   = 1;
        wr_data = 8'hFF;  // this write should be silently ignored
        @(posedge clk);
        #1;
        wr_en = 0;
        check(full == 1, "still full after attempted overflow write (ignored)");

        // ---- Test 4: drain completely, verify FIFO order ----
        $display("--- Draining FIFO, checking order ---");
        for (i = 0; i < DEPTH; i = i + 1) begin
            @(negedge clk);
            #1;
            check(rd_data == i, "read value matches write order");
            rd_en = 1;
            @(posedge clk);
            #1;
        end
        @(negedge clk);
        rd_en = 0;
        #1;
        check(empty == 1, "empty asserts after reading all DEPTH items");

        // ---- Test 5: underflow protection ----
        @(negedge clk);
        rd_en = 1;  // this read should be silently ignored (nothing to read)
        @(posedge clk);
        #1;
        rd_en = 0;
        check(empty == 1, "still empty after attempted underflow read (ignored)");

        // ---- Test 6: simultaneous read+write while partially full ----
        $display("--- Simultaneous read+write test ---");
        // First, write 3 items to have something to read from
        for (i = 0; i < 3; i = i + 1) begin
            @(negedge clk);
            wr_en = 1; wr_data = 8'hA0 + i[7:0];
            @(posedge clk); #1;
        end
        @(negedge clk); wr_en = 0; #1;

        // Now read and write on the same cycles simultaneously for a while
        for (i = 0; i < 5; i = i + 1) begin
            @(negedge clk);
            wr_en = 1; wr_data = 8'hB0 + i[7:0];
            rd_en = 1;
            @(posedge clk); #1;
        end
        @(negedge clk); wr_en = 0; rd_en = 0; #1;
        check(empty == 0, "FIFO has data after simultaneous read/write burst");
        $display("(Fill level after simultaneous burst - visual check in waveform)");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

    // Safety timeout
    initial begin
        #100000;
        $display("TIMEOUT - simulation did not finish");
        $finish;
    end

endmodule
