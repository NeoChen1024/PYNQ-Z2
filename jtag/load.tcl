# Configures the PL of the XC7Z020 over the JTAG of the board (the FT2232H on J8). Nothing is written to
# the QSPI flash or the card. The PS keeps running.
#
#   vivado -mode batch -source load.tcl -tclargs <bitstream>
lassign $argv bit
open_hw_manager
connect_hw_server
open_hw_target
# The chain has the ARM DAP and the PL; only the PL takes a bitstream.
set device [lindex [get_hw_devices xc7z020*] 0]
if {$device eq ""} { error "no xc7z020 in the chain: [get_hw_devices]" }
current_hw_device $device
set_property PROGRAM.FILE $bit $device
program_hw_devices $device
refresh_hw_device -update_hw_probes false $device
puts "DONE=[get_property REGISTER.IR.BIT5_DONE $device]"
close_hw_target
disconnect_hw_server
close_hw_manager
