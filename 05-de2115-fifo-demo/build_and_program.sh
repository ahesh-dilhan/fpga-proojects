#!/bin/bash
# =========================================================================
# build_and_program.sh
#
# Runs the full Quartus flow from the command line: no GUI needed until
# (optionally) you want to look at reports.
#
# Prerequisite: Quartus's bin directory must be on your PATH, e.g.:
#   export PATH=$PATH:~/intelFPGA_lite/21.1/quartus/bin
#
# Usage:
#   cd de2115-fifo-demo-cli
#   bash build_and_program.sh
# =========================================================================
set -e

echo "=== Running full compile flow (synthesis -> fit -> assemble -> STA) ==="
quartus_sh --flow compile fifo_demo

echo ""
echo "=== Compile finished. Checking for the bitstream file... ==="
if [ -f output_files/fifo_demo.sof ]; then
    echo "Found: output_files/fifo_demo.sof"
else
    echo "ERROR: output_files/fifo_demo.sof not found - compile likely failed."
    echo "Check the messages above for errors."
    exit 1
fi

echo ""
echo "=== Checking for connected programming hardware ==="
quartus_pgm -l

echo ""
read -p "Ready to program the board? Make sure RUN/PROG switch is set to RUN. Press Enter to continue, Ctrl+C to abort..."

echo ""
echo "=== Programming the board ==="
quartus_pgm -c "USB-Blaster" -m jtag -o "p;output_files/fifo_demo.sof"

echo ""
echo "=== Done. Test it: set SW[7:0], press KEY0 to write, KEY1 to read. ==="
