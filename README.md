# FPGA Project Template (Zynq-7000 / Vivado ML)

Clean, reproducible structure for FPGA projects. The Vivado project itself
is **never committed** — it's regenerated from source using `scripts/build.tcl`.
This keeps the git history readable and avoids merge conflicts on binary
Vivado project files.

## Folder structure

```
.
├── src/           RTL source files (.v / .sv / .vhd) - synthesizable design only
├── sim/           Testbenches (.v / .sv / .vhd) - simulation only, never synthesized
├── constraints/   .xdc constraint files (pin mapping, timing)
├── scripts/       build.tcl and other Tcl automation
├── docs/          Notes, block diagrams, waveform screenshots, reports
└── build/         (gitignored) Vivado auto-generates this when you run build.tcl
```

## Workflow

### 1. Simulate first (Verilator / GTKWave, in your Docker container)
```bash
verilator --binary --trace sim/my_module_tb.sv src/my_module.sv
./obj_dir/Vmy_module_tb
gtkwave dump.vcd
```
Catch bugs here before ever opening Vivado — much faster iteration.

### 2. Build the Vivado project from source
```bash
vivado -mode batch -source scripts/build.tcl
```
This creates a `build/` folder with the actual `.xpr` project (gitignored).
Edit the `part_name` and `top` module variables inside `build.tcl` for your
board and current project.

### 3. Open in Vivado GUI (optional, for waveform/synthesis inspection)
```bash
vivado build/my_fpga_project.xpr
```

### 4. Simulate, synthesize, implement, generate bitstream — all doable
without the board connected. Only "Program Device" needs real hardware.

### 5. Once you have the board: Open Hardware Manager → Program Device.

## Git conventions
- Only commit `src/`, `sim/`, `constraints/`, `scripts/`, `docs/`, and this README.
- Never commit `build/`, `*.xpr`, `*.bit`, `.Xil/`, `*.cache/`, `*.runs/`, `*.sim/`
  (already handled by `.gitignore`).
- One project = one repo (or one subfolder per project if you want a monorepo
  of small projects — see note below).

## Suggested repo layout if tracking multiple small projects

```
fpga-projects/
├── 01-debounced-led/
├── 02-uart-tx-rx/
├── 03-traffic-light-fsm/
├── 04-axi-lite-gpio/
└── ...
```
Each subfolder follows the structure above. This makes a great portfolio
to show during industrial training interviews — clear progression, clean
history, reproducible builds.
# fpga-proojects
