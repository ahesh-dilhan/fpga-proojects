# DE2-115 FIFO Demo - Command-Line Quartus Flow

Same design as `de2115-fifo-demo.zip`, but set up so you never need to
open the New Project Wizard, Pin Planner, or click through the GUI at
all. The `.qpf`/`.qsf` files ARE the project - Quartus's command-line
tools read them directly.

## Files
```
fifo_demo.qpf          Quartus Project File (minimal, points to revision)
fifo_demo.qsf          Full project settings: device, top-level, source
                        files, and ALL pin assignments in one file
src/fifo_demo_top.v    Top-level design
src/sync_fifo.v        Your FIFO from Project 04
src/debounce.v         Your debounce module from Project 01
build_and_program.sh   Runs the whole compile + program flow in one go
```

## One-time setup: put Quartus on your PATH
```bash
export PATH=$PATH:~/intelFPGA_lite/21.1/quartus/bin
```
(add this to `~/.bashrc` if you haven't already, so it's permanent)

## Run everything with one command
```bash
cd de2115-fifo-demo-cli
chmod +x build_and_program.sh
bash build_and_program.sh
```
This runs, in order:
1. `quartus_sh --flow compile fifo_demo` - synthesis, fitting (place &
   route), assembly (bitstream generation), and timing analysis, all in
   one command. This is the CLI equivalent of clicking "Start
   Compilation" in the GUI.
2. Checks the `.sof` bitstream was actually produced
3. `quartus_pgm -l` - lists connected programming hardware, so you can
   confirm your USB-Blaster is detected before trying to program
4. Pauses so you can double check the RUN/PROG switch is set to RUN
5. `quartus_pgm -c "USB-Blaster" -m jtag -o "p;output_files/fifo_demo.sof"`
   - programs the board

## Doing it manually, step by step (if you'd rather run each piece yourself)
```bash
# Full compile (synth + fit + assemble + STA):
quartus_sh --flow compile fifo_demo

# OR run each stage separately, if you want to inspect between steps:
quartus_map fifo_demo    # Analysis & Synthesis
quartus_fit fifo_demo    # Fitter (place & route)
quartus_asm fifo_demo    # Assembler (generates the .sof bitstream)
quartus_sta fifo_demo    # Timing analysis (optional but good practice)

# Check what programming hardware is detected:
quartus_pgm -l

# Program the board:
quartus_pgm -c "USB-Blaster" -m jtag -o "p;output_files/fifo_demo.sof"
```

## Reading reports without the GUI
After compiling, useful reports live in `output_files/`:
```bash
cat output_files/fifo_demo.fit.summary     # resource utilization summary
cat output_files/fifo_demo.sta.rpt | less  # timing analysis report
```

## If something goes wrong
- **`quartus_sh: command not found`** - Quartus isn't on your PATH. Check
  the export command above, or find the actual bin path with:
  `find ~ -maxdepth 4 -iname "quartus_sh" 2>/dev/null`
- **Compile errors** - paste the exact error text, don't guess-fix it
- **`quartus_pgm -l` shows nothing** - USB-Blaster driver/udev rule issue
  (same as before), or the board isn't powered on, or the cable isn't
  plugged in
- **Programs but nothing happens on the board** - double-check RUN/PROG
  switch (SW19) is set to RUN, not PROG

## Once this works
You now have a fully scriptable, git-friendly Quartus flow - same
philosophy as the `build.tcl` approach we used for Vivado. Every future
DE2-115 project can follow this exact same `.qpf` + `.qsf` + source files
+ one build script pattern.
