// =========================================================================
// sync_fifo.v
//
// Synchronous FIFO (First-In-First-Out buffer). DEPTH must be a power of
// 2 - this design uses the classic "extra pointer bit" trick to tell full
// apart from empty using only pointer comparison, no separate counter.
//
// How full/empty detection works:
//   Both wr_ptr and rd_ptr are ADDR_WIDTH+1 bits wide - one bit wider than
//   needed to just address the memory. The extra top bit acts as a "lap
//   counter" that flips every time a pointer wraps around the buffer.
//     - EMPTY: wr_ptr == rd_ptr (both pointers on the same lap, same slot)
//     - FULL:  same lower ADDR_WIDTH bits (same slot) but DIFFERENT top
//              bit (write pointer has lapped the read pointer once)
//   This avoids needing a separate up/down counter to track fill level.
//
// Read behavior: "fall-through" style - rd_data always shows the value at
// the current read pointer (combinational), and rd_ptr only advances when
// rd_en is asserted and the FIFO isn't empty.
// =========================================================================
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 8          // MUST be a power of 2
) (
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   wr_en,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire                   full,

    input  wire                   rd_en,
    output wire [DATA_WIDTH-1:0]  rd_data,
    output wire                   empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_WIDTH:0] wr_ptr;  // 1 extra bit vs. what's needed to address mem
    reg [ADDR_WIDTH:0] rd_ptr;

    wire wr_allowed = wr_en && !full;
    wire rd_allowed = rd_en && !empty;

    // ---- Write logic ----
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_allowed) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // ---- Read logic ----
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (rd_allowed) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    assign rd_data = mem[rd_ptr[ADDR_WIDTH-1:0]];

    // ---- Full / empty flags ----
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
                   (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);

endmodule
