# Project 01 - Debounced Button → LED

Two patterns in one small design:
- **btn0 → led0**: "follow" mode. LED lit only while button is held.
- **btn1 → led1**: "toggle" mode. Each clean press flips the LED (edge-triggered).

Both buttons are debounced through a shared, reusable `debounce` module.

## Files
```
src/debounce.v          Reusable debounce module (parameterized cycle count)
src/btn_led_top.v       Top-level design, instantiates debounce x2
sim/tb_btn_led_top.v    Testbench - verifies clean press, bouncy press, and toggle
constraints/zybo_z7.xdc Pin mapping for Zybo Z7 (Z7-10 and Z7-20 both use these pins)
scripts/build.tcl       Recreates the Vivado project from source
```

## 1. Simulate first (already verified working - see below)
```bash
verilator --binary --trace sim/tb_btn_led_top.v src/btn_led_top.v src/debounce.v \
    --top-module tb_btn_led_top -Wno-fatal
./obj_dir/Vtb_btn_led_top
```
Expected output: 6x PASS, no FAIL lines.

To view the waveform:
```bash
gtkwave dump.vcd
```
Useful signals to look at: `btn0`, `btn0_clean` (inside `dut.u_debounce_btn0`),
and `led0` - watch how `btn0_clean` stays flat during the bouncy test even
though `btn0` itself is glitching.

## 2. Build in Vivado (no board needed yet)
```bash
vivado -mode batch -source scripts/build.tcl
```
**Before running:** open `scripts/build.tcl` and confirm the `part_name`
matches your exact board (Z7-10 vs Z7-20 - check the board silkscreen).

This gets you through synthesis, implementation, and bitstream generation
without the board connected. Only the final "Program Device" step needs
real hardware.

## 3. Program the board (once you have it)
Open Hardware Manager in Vivado → Open Target → Auto Connect → Program Device
→ select the generated `.bit` file.

## What to try once it's running
- Press and hold btn0 → led0 lights up only while held
- Press and release btn1 → led1 flips and stays flipped
- Press btn2 (wired as reset) → both LEDs clear

## Why this project first
This is deliberately small so the *workflow* is the thing you learn:
simulate → synthesize → implement → generate bitstream → program. Every
later project (UART, FSM, AXI peripheral) follows this exact same loop,
just with more complex RTL. Also: debounce + edge detection show up
constantly in real designs, so this isn't just a toy - `debounce.v` is
genuinely reusable in every future project you'll do.
