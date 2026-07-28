# =========================================================================
# zybo_z7.xdc
#
# Pin constraints for the Zybo Z7 (both Z7-10 and Z7-20 share this pinout
# for clock, buttons, and LEDs - only the FPGA part number differs between
# the two variants, which is set separately in build.tcl / Project Settings).
#
# Source: Digilent's official Zybo Z7 Master XDC (only the pins we use here
# are uncommented; the rest of the board's I/O is left out since this
# project doesn't use it).
# =========================================================================

## Clock signal (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn1 }];

## LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led0 }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led1 }];

## Reset - using a third button (btn2) as active-high reset.
## If you'd rather not use a button for reset, comment this out and tie
## rst to 0 in the design, or use a switch instead (e.g. pin M19 = sw0).
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { rst }];
