// =========================================================================
// fifo_demo_top.v
//
// Interactive FIFO demo for the DE2-115. Since a FIFO has no visible
// behavior on its own, this wraps it with physical controls:
//
//   SW[7:0]  - the byte to write (set with switches before pressing KEY0)
//   KEY0     - "write" button: pushes the current SW[7:0] value into the FIFO
//   KEY1     - "read" button: pops the oldest value out of the FIFO
//   KEY2     - reset (clears the FIFO entirely)
//
//   LEDR[7:0] - shows the LAST VALUE READ OUT of the FIFO (updates only
//               when you press KEY1 and the FIFO wasn't empty)
//   LEDR[8]   - lit when FIFO is FULL (further writes are ignored)
//   LEDR[9]   - lit when FIFO is EMPTY (further reads are ignored)
//
// Try this: set SW to some value, press KEY0 several times with DIFFERENT
// switch settings each time (e.g. 0x01, 0x02, 0x03...). Then press KEY1
// repeatedly - LEDR[7:0] should show 0x01, then 0x02, then 0x03, in the
// SAME ORDER you wrote them. That's the entire point of a FIFO made
// physically visible: first in, first out.
//
// Note: DE2-115 push buttons are ACTIVE LOW (0 = pressed), so they're
// inverted before being fed into the (active-high) debounce module.
// =========================================================================
module fifo_demo_top (
    input  wire       CLOCK_50,
    input  wire [2:0] KEY,      // KEY[0]=write, KEY[1]=read, KEY[2]=reset
    input  wire [7:0] SW,
    output wire [9:0] LEDR
);

    wire clk = CLOCK_50;

    // ---- Reset (debounced, active-high internally) ----
    wire rst_raw = ~KEY[2];   // pressed = 0 on the board, so invert
    wire rst;
    debounce #(.DEBOUNCE_CYCLES(500000)) u_debounce_rst (   // ~10ms at 50MHz
        .clk(clk), .rst(1'b0), .btn_in(rst_raw), .btn_out(rst)
    );

    // ---- Write button (debounce + edge detect -> single-cycle pulse) ----
    wire wr_btn_raw = ~KEY[0];
    wire wr_btn_clean;
    debounce #(.DEBOUNCE_CYCLES(500000)) u_debounce_wr (
        .clk(clk), .rst(rst), .btn_in(wr_btn_raw), .btn_out(wr_btn_clean)
    );
    reg wr_btn_clean_d;
    wire wr_en = wr_btn_clean && !wr_btn_clean_d;
    always @(posedge clk) begin
        if (rst) wr_btn_clean_d <= 1'b0;
        else     wr_btn_clean_d <= wr_btn_clean;
    end

    // ---- Read button (same pattern) ----
    wire rd_btn_raw = ~KEY[1];
    wire rd_btn_clean;
    debounce #(.DEBOUNCE_CYCLES(500000)) u_debounce_rd (
        .clk(clk), .rst(rst), .btn_in(rd_btn_raw), .btn_out(rd_btn_clean)
    );
    reg rd_btn_clean_d;
    wire rd_en = rd_btn_clean && !rd_btn_clean_d;
    always @(posedge clk) begin
        if (rst) rd_btn_clean_d <= 1'b0;
        else     rd_btn_clean_d <= rd_btn_clean;
    end

    // ---- The FIFO itself ----
    wire [7:0] fifo_rd_data;
    wire full, empty;

    sync_fifo #(.DATA_WIDTH(8), .DEPTH(8)) u_fifo (
        .clk(clk), .rst(rst),
        .wr_en(wr_en), .wr_data(SW),
        .full(full),
        .rd_en(rd_en), .rd_data(fifo_rd_data),
        .empty(empty)
    );

    // ---- Latch the value at the moment it's actually popped ----
    // fifo_rd_data is combinational ("what's at the front right now"), so
    // we capture it on the exact same edge the pop happens, giving a
    // stable display value that holds until the next successful read.
    reg [7:0] displayed_data;
    always @(posedge clk) begin
        if (rst) begin
            displayed_data <= 8'h00;
        end else if (rd_en && !empty) begin
            displayed_data <= fifo_rd_data;
        end
    end

    assign LEDR[7:0] = displayed_data;
    assign LEDR[8]   = full;
    assign LEDR[9]   = empty;

endmodule
