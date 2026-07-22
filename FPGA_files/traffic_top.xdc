## Clock (100 MHz oscillator)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin [get_ports clk]

## Reset - center pushbutton (BTNC)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## UART receive (USB-UART RX - directly from FTDI chip)
set_property PACKAGE_PIN B18 [get_ports rx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports rx_pin]

## UART transmit (USB-UART TX - directly to FTDI chip)
set_property PACKAGE_PIN A18 [get_ports tx_pin]
set_property IOSTANDARD LVCMOS33 [get_ports tx_pin]

## LIGHT 1 (2-bit vector)
set_property PACKAGE_PIN U16 [get_ports {light_1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {light_1[0]}]
set_property PACKAGE_PIN E19 [get_ports {light_1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {light_1[1]}]

## LIGHT 2 (2-bit vector)
set_property PACKAGE_PIN V19 [get_ports {light_2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {light_2[0]}]
set_property PACKAGE_PIN W18 [get_ports {light_2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {light_2[1]}]

## FPGA configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]