# Samples the boundary register of the PL TAP of the XC7Z020 with SAMPLE (000001): the pins do not
# change. With "clear", it first sends JPROGRAM (001011), which clears the PL; the PS keeps running.
#
#   xsdb sample.tcl LENGTH [clear]      prints "BSR <bits>", cell 0 first
#
# LENGTH is BOUNDARY_LENGTH of the BSDL file (1077 for xc7z020_clg400.bsd). bsdl_inputs.py maps the bits
# to the pins.
lassign $argv len clear
connect
jtag targets -set -filter {name == "xc7z020"}
if {$clear eq "clear"} {
    set seq [jtag sequence]
    $seq irshift -state IDLE -bits 6 110100
    $seq state IDLE 1000
    $seq run
    $seq delete
    after 500
}
set seq [jtag sequence]
$seq irshift -state IDLE -bits 6 100000
$seq drshift -state IDLE -capture -tdi 0 $len
puts "BSR [lindex [$seq run -bits] 0]"
$seq delete
disconnect
