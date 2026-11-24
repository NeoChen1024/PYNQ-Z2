# Measures the write and read data eye of each DDR byte lane of the PYNQ-Z2 over JTAG. The PS must
# wait at the U-Boot prompt: the script stops both CPUs, and only the host touches the DDR, through
# the DAP. For each setting it writes a test block to the DDR, reads it back and counts the wrong bits
# of each lane. All changes are to volatile registers of the DDR PHY, and the script restores them.
#
#   xsdb ddr_eye.tcl [WORDS]        prints CSV: kind,lane,setting,errors_lane0,errors_lane1
#
# kind "wr": a forced write data slave delay (DLL taps) of the lane, the write data eye.
# kind "rd": a forced read DQS slave delay (DLL taps) of the lane, the read data eye.
# Both use the force bit of the PHY register: a new ratio takes effect only at the next initialization
# of the DDR, but a forced delay takes effect at once (measured 2026-11-24). "taps" gives the delays
# that the PHY applied before the scan (phy_dll_sts).
# The bus is 16 bits wide: lane 0 has the bytes 0 and 2 of each 32-bit word, lane 1 the bytes 1 and 3.
# The test block (WORDS 32-bit words, 2048 by default) is at 0x10000000, which U-Boot does not use.
set words [expr {[llength $argv] ? [lindex $argv 0] : 2048}]
set base 0x10000000
set WR_DATA {0xF800617C 0xF8006180}
set RD_DQS  {0xF8006140 0xF8006144}

# The test data: a 32-bit LFSR, with every eighth word 0x00000000, 0xFFFFFFFF, 0x55555555 or 0xAAAAAAAA,
# so that the block has both random data and full-swing patterns.
set data {}
set x 0x12345678
for {set i 0} {$i < $words} {incr i} {
    set x [expr {(($x << 1) | ((($x >> 31) ^ ($x >> 21) ^ ($x >> 1) ^ $x) & 1)) & 0xFFFFFFFF}]
    switch [expr {$i % 32}] {
        8 { lappend data 0x00000000 } 16 { lappend data 0xFFFFFFFF }
        24 { lappend data 0x55555555 } 31 { lappend data 0xAAAAAAAA }
        default { lappend data $x }
    }
}

proc popcount {v} { set n 0; while {$v} { incr n [expr {$v & 1}]; set v [expr {$v >> 1}] }; return $n }
proc errors {} {
    global base words data
    set got [mrd -force -value $base $words]
    set e0 0; set e1 0
    foreach a $data b $got {
        set d [expr {$a ^ $b}]
        if {$d} {
            incr e0 [popcount [expr {$d & 0x00FF00FF}]]
            incr e1 [popcount [expr {$d & 0xFF00FF00}]]
        }
    }
    return [list $e0 $e1]
}
proc write_block {} { global base data; mwr -force $base $data }

connect
foreach n {0 1} { targets -set -nocase -filter "name =~ \"*Cortex-A9*#$n\""; catch {stop} }
targets -set -nocase -filter {name =~ "APU*"}
set saved {}
foreach a [concat $WR_DATA $RD_DQS] { lappend saved $a [mrd -force -value $a] }
puts "# saved [join $saved { }]"
foreach lane {0 1} a {0xF80061CC 0xF80061D0} {
    set v [mrd -force -value $a]
    puts [format "taps,%d,wr_dqs=%d wr_data=%d rd_dqs=%d,-,-" $lane [expr {($v >> 18) & 0x1FF}] [expr {($v >> 9) & 0x1FF}] [expr {$v & 0x1FF}]]
}

write_block
lassign [errors] e0 e1
puts "base,-,-,$e0,$e1"

# Write eye: the delay of one lane moves, the other lane keeps its value.
for {set lane 0} {$lane < 2} {incr lane} {
    set reg [lindex $WR_DATA $lane]
    set nominal [dict get $saved $reg]
    for {set t 0} {$t <= 240} {incr t 4} {
        mwr -force $reg [expr {($t << 11) | (1 << 10) | ($nominal & 0x3FF)}]
        write_block
        lassign [errors] e0 e1
        puts "wr,$lane,$t,$e0,$e1"
    }
    mwr -force $reg $nominal
}

# Read eye: the data is written with the saved settings, then read with forced read DQS delays.
write_block
for {set lane 0} {$lane < 2} {incr lane} {
    set reg [lindex $RD_DQS $lane]
    set nominal [dict get $saved $reg]
    for {set t 0} {$t <= 80} {incr t 2} {
        mwr -force $reg [expr {($t << 11) | (1 << 10) | ($nominal & 0x3FF)}]
        lassign [errors] e0 e1
        puts "rd,$lane,$t,$e0,$e1"
    }
    mwr -force $reg $nominal
}

foreach {a v} $saved { mwr -force $a $v }
write_block
lassign [errors] e0 e1
puts "restored,-,-,$e0,$e1"
foreach n {0 1} { targets -set -nocase -filter "name =~ \"*Cortex-A9*#$n\""; catch {con} }
disconnect
