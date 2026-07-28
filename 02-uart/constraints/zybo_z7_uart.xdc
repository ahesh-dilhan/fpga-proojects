# =========================================================================
# zybo_z7_uart.xdc
#
# Pin constraints for the UART loopback project on Zybo Z7.
#
# UART TX/RX use Pmod JA pins 1 and 2 (ja[0], ja[1]) instead of the
# board's built-in USB-UART bridge, because that bridge is wired to the
# Zynq PS (processor) side via MIO pins - not reachable from pure PL
# (fabric) Verilog without a full Zynq block design. Using a Pmod keeps
# this a pure-RTL project.
#
# To test: after programming the board, connect a jumper wire from
# Pmod JA pin 1 to Pmod JA pin 2 (i.e. ja[0] to ja[1]) - this is your
# physical loopback path.
#
# Source: Digilent's official Zybo Z7 Master XDC.
# =========================================================================

## Clock signal (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Button (transmit trigger)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];

## Reset (using btn2)
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { rst }];

## LEDs (display received byte's lower nibble)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## Pmod JA - uart_tx_pin on ja[0] (pin 1), uart_rx_pin on ja[1] (pin 2)
set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { uart_tx_pin }]; # ja[0]
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { uart_rx_pin }]; # ja[1]
