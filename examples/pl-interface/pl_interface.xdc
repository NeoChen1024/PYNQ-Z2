## The lines of pynq_z2_master.xdc that pl-interface uses, and its clocks.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS33 } [get_ports { sysclk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];
set_property -dict { PACKAGE_PIN R14  IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN P14  IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN N16  IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN M14  IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## FCLK0: 100 MHz in the board preset (docs/pl-interface.md). The PS7 cell itself defines no clock.
create_clock -name fclk0 -period 10.000 [get_pins ps7_i/FCLKCLK[0]]

## The only path between the clocks is the Gray code of the SYSCLK counter: one bit changes per step,
## so a delay of one SYSCLK period is enough.
set_max_delay -datapath_only -from [get_cells {sys_gray_reg[*]}] -to [get_cells {sys_gray_s1_reg[*]}] 8.000

## The LEDs change slowly; no timing applies to them.
set_false_path -to [get_ports {led[*]}]
