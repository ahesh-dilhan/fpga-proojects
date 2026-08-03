# Project 04 - Synchronous FIFO

A First-In-First-Out buffer - one of the most fundamental and widely
reused building blocks in digital design. Any time data needs to cross
between two different rates, bursts, or timing contexts, a FIFO shows up.
This one pairs naturally with your UART project (Project 02): a
UART+FIFO combo is the standard pattern for buffered serial communication.

## Files
```
src/sync_fifo.v      The FIFO itself - parameterized width and depth
sim/tb_sync_fifo.v   Testbench covering fill, drain, overflow/underflow
                      protection, and simultaneous read+write
```

## How it works
DEPTH must be a power of 2. Full/empty detection uses a classic trick:
both read and write pointers are one bit WIDER than needed to just
address the memory. That extra top bit acts as a "lap counter":

- **Empty**: `wr_ptr == rd_ptr` exactly (same lap, same slot)
- **Full**: same lower address bits (same slot) but the extra top bit
  differs (write pointer has lapped the read pointer exactly once)

This avoids needing a separate up/down counter just to track fill level -
pointer comparison alone tells you everything.

Reads are "fall-through" style: `rd_data` always shows whatever's at the
current read pointer combinationally; `rd_en` just controls whether the
pointer advances afterward.

## Already verified in simulation
```
PASS: starts empty, not full
--- Filling FIFO (writing 8 items) ---
PASS: not full before last write   (x7)
PASS: full asserts after writing DEPTH items
PASS: still full after attempted overflow write (ignored)
--- Draining FIFO, checking order ---
PASS: read value matches write order   (x8)
PASS: empty asserts after reading all DEPTH items
PASS: still empty after attempted underflow read (ignored)
--- Simultaneous read+write test ---
PASS: FIFO has data after simultaneous read/write burst
ALL TESTS PASSED
```

The two most important checks here aren't the "happy path" (write then
read) - they're the **overflow/underflow protection** (does the FIFO
correctly ignore illegal operations instead of corrupting data or
wrapping incorrectly?) and the **simultaneous read+write** case (do both
pointers update correctly on the same clock edge without interfering
with each other?). Those are exactly the edge cases that are easy to get
subtly wrong and hard to catch without deliberately testing for them.

## Run it yourself
```bash
verilator --binary --trace sim/tb_sync_fifo.v src/sync_fifo.v \
    --top-module tb_sync_fifo -Wno-fatal
./obj_dir/Vtb_sync_fifo
```

```bash
gtkwave dump.vcd
```
Useful signals: `wr_ptr`, `rd_ptr` (inside `dut`), `full`, `empty`,
`rd_data`. Watch how `wr_ptr` and `rd_ptr`'s lower bits align exactly at
both the empty state (start) and full state (after 8 writes) - and how
the difference is only that extra top bit.

## What's next
This FIFO is now a reusable block, same as `debounce.v` and the UART
pair. A natural next step: combine `uart_rx.v` (Project 02) with this
FIFO so received bytes queue up instead of needing to be consumed
immediately - a realistic buffered-UART design.
