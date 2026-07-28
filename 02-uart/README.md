# Project 02 - UART TX/RX (Loopback Test)

A from-scratch UART transmitter and receiver in Verilog, tested via a
physical loopback wire on a Pmod header. This is one of the most broadly
useful building blocks in FPGA/embedded work - almost every board-to-PC
or board-to-board communication project starts here.

## Files
```
src/uart_tx.v              Transmitter: byte in -> serial bits out, 8N1 frame
src/uart_rx.v              Receiver: serial bits in -> byte out, 8N1 frame
src/debounce.v             Reused from Project 01
src/uart_loopback_top.v    Top-level: btn0 press -> transmit incrementing byte
                            -> received back via jumper wire -> shown on LEDs
sim/tb_uart_loopback.v     Testbench: verifies TX and RX round-trip correctly
constraints/zybo_z7_uart.xdc  Pin mapping (uses Pmod JA, not the USB-UART bridge)
scripts/build.tcl          Recreates the Vivado project from source
```

## Why Pmod JA instead of the onboard USB-UART?
The Zybo Z7's built-in USB-UART bridge (the one you talk to over the
Micro USB cable) is wired to the **Zynq PS (processor) side** through
MIO pins, not the FPGA fabric (PL). Reaching it from pure Verilog would
require building a Zynq block design with the PS UART controller - a
different, more advanced workflow. Using Pmod JA instead keeps this a
pure-RTL project you can build entirely from Vivado's RTL flow.

## 1. Simulate first (already verified - see below)
```bash
verilator --binary --trace sim/tb_uart_loopback.v src/uart_tx.v src/uart_rx.v \
    --top-module tb_uart_loopback -Wno-fatal
./obj_dir/Vtb_uart_loopback
```
Expected: 4x PASS (tests 0x00, 0xFF, 0xA5, 0x55 - chosen because the
alternating-bit patterns are the hardest case for start/stop bit timing).

```bash
gtkwave dump.vcd
```
Useful signals: `tx_serial`/`serial_line` (the actual bitstream on the
wire), `tx_data`, `rx_data`. Zoom in on one byte transmission and count
the bits by eye: start bit (0), 8 data bits LSB-first, stop bit (1).

## 2. Lint-check the top module (also already verified)
```bash
verilator --lint-only src/uart_loopback_top.v src/uart_tx.v src/uart_rx.v \
    src/debounce.v --top-module uart_loopback_top -Wno-fatal
```

## 3. Build in Vivado
```bash
vivado -mode batch -source scripts/build.tcl
```
Confirm `part_name` in `build.tcl` matches your board (Z7-10 vs Z7-20)
before running.

## 4. Program the board and test
1. Program the generated bitstream via Hardware Manager.
2. **Connect a jumper wire from Pmod JA pin 1 to Pmod JA pin 2** (this is
   the physical TX-to-RX loopback path - ja[0] to ja[1]).
3. Press btn0 repeatedly. Watch the 4 LEDs count up in binary: 0000,
   0001, 0010, 0011, ... Each press transmits the next byte value, which
   loops back through the wire, gets received, and is displayed almost
   instantly (well under 1ms at 115200 baud - looks instant to the eye).
4. If you don't have a jumper wire handy, you can instead verify the TX
   side alone with a logic analyzer or oscilloscope probe on ja[0], or
   use a USB-to-serial adapter set to 115200 8N1 to see the actual bytes
   on a PC terminal.

## What's next
This UART pair is now a reusable building block, same as `debounce.v`.
Later projects (e.g. an AXI-Lite peripheral controlled from the ARM
core, or a simple protocol/packet framer) can reuse `uart_tx.v` and
`uart_rx.v` directly.
