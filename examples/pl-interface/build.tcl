# Synthesis, place and route of pl-interface, without a project. build.sh runs it in the work directory.
#
#   vivado -mode batch -source build.tcl -tclargs <top> <part> <constraints> <source> ...
set sources [lassign $argv top part constraints]
read_verilog -sv $sources
read_xdc $constraints
synth_design -top $top -part $part
opt_design
place_design
route_design
report_timing_summary -file timing.rpt
report_utilization -file utilization.rpt
report_clock_interaction -file clocks.rpt
report_io -file io.rpt
report_drc -file drc.rpt
write_bitstream -force $top.bit
