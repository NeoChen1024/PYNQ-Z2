# Makes the PS7 configuration of the PYNQ-Z2 from the preset of the board file (board-files/), and
# exports it: the hardware platform (pynq-z2.xsa) and the PS initialization (ps7_init_gpl.c,
# ps7_init_gpl.h, ps7_init.tcl). build.sh runs it in the work directory.
#
#   vivado -mode batch -source ps7.tcl -tclargs <board-files directory>
lassign $argv boards
set_param board.repoPaths [list $boards]
create_project -force ps7 proj -part xc7z020clg400-1
set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]
create_bd_design ps7
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} [get_bd_cells ps7]
# No PL design uses the PS here: an enabled AXI port without a clock fails the validation.
set_property CONFIG.PCW_USE_M_AXI_GP0 0 [get_bd_cells ps7]
validate_bd_design
save_bd_design
generate_target all [get_files ps7.bd]
add_files -norecurse [make_wrapper -files [get_files ps7.bd] -top]
write_hw_platform -fixed -force -file pynq-z2.xsa
foreach f {ps7_init_gpl.c ps7_init_gpl.h ps7_init.tcl ps7_init.html} {
    set found [glob -nocomplain proj/ps7.gen/sources_1/bd/ps7/ip/*/$f]
    if {[llength $found] != 1} { error "not one $f: $found" }
    file copy -force [lindex $found 0] $f
}
