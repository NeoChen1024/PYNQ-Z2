# Reads and controls pinprobe (pinprobe.sv) through USER1 of the PL TAP. Load a bitstream of build.sh
# first (jtag/load.sh). Each command writes the whole control word: a command that does not name a
# drive releases all drives.
#
#   xsdb pinprobe.tcl pinmap.csv read              all pins and the status
#   xsdb pinprobe.tcl pinmap.csv watch SECONDS [hpd0|hpd1]   print each pin that changes, as it
#                                                  changes; hpd0/hpd1 drive the HPD of HDMI_IN meanwhile
#   xsdb pinprobe.tcl pinmap.csv i2c [mclk] [adr1low]   scan 0x08 to 0x77 on the codec I2C
#   xsdb pinprobe.tcl pinmap.csv hpd 0|1           drive the HPD of HDMI_IN, and keep it driven
#
# pinmap.csv comes from the same build as the bitstream.
set args [lassign $argv mapfile cmd]
set pins {}
set f [open $mapfile]
gets $f
while {[gets $f line] >= 0} { lappend pins [split $line ,] }
close $f
set N [llength $pins]
set C [expr {16 + $N + 128}]

connect
jtag targets -set -filter {name == "xc7z020"}

# Shifts the control word into USER1 and returns the captured bits as a list, bit 0 first.
proc shift {ctrl} {
    global C
    set nbytes [expr {($C + 7) / 8}]
    # 0xC3 is the key that makes pinprobe take the control byte.
    set hex [format %02xc3 [expr {$ctrl & 0xff}]]
    append hex [string repeat 00 [expr {$nbytes - 2}]]
    set seq [jtag sequence]
    $seq irshift -state IDLE -hex 6 02
    $seq drshift -state IDLE -capture -hex $C $hex
    set r [lindex [$seq run -hex] 0]
    $seq delete
    set bits {}
    foreach {a b} [split $r ""] {
        scan $a$b %x v
        for {set j 0} {$j < 8} {incr j} { lappend bits [expr {($v >> $j) & 1}] }
    }
    if {[field $bits 0 8] != 0xa5} { error "no pinprobe in the PL (signature [format %02x [field $bits 0 8]])" }
    return $bits
}
proc field {bits lo n} {
    set v 0
    for {set i [expr {$lo + $n - 1}]} {$i >= $lo} {incr i -1} { set v [expr {($v << 1) | [lindex $bits $i]}] }
    return $v
}
proc status {bits} {
    set s [field $bits 8 8]
    return [format "busy=%d done=%d sysclk=%d mclk=%d build=%s" [expr {$s & 1}] [expr {($s >> 1) & 1}] \
        [expr {($s >> 2) & 1}] [expr {($s >> 3) & 1}] [expr {($s >> 4) & 1 ? "PULLUP" : "PULLDOWN"}]]
}
proc pinval {bits i} { return [lindex $bits [expr {16 + $i}]] }

switch -- $cmd {
    read {
        set b [shift 0]
        puts "# [status $b]"
        puts "index,pin,port,value"
        set i 0
        foreach p $pins { puts "[join $p ,],[pinval $b $i]"; incr i }
    }
    watch {
        set secs [lindex $args 0]
        set ctrl 0
        if {"hpd0" in $args} { set ctrl 0x40 }
        if {"hpd1" in $args} { set ctrl 0xc0 }
        set b [shift $ctrl]
        puts "# [status $b]; watching for $secs s, control [format 0x%02x $ctrl]"
        set prev {}
        for {set i 0} {$i < $N} {incr i} { lappend prev [pinval $b $i] }
        set end [expr {[clock milliseconds] + 1000 * $secs}]
        set alive [field $b 10 1]; set alive_changes 0
        while {[clock milliseconds] < $end} {
            set b [shift $ctrl]
            if {[field $b 10 1] != $alive} { set alive [field $b 10 1]; incr alive_changes }
            for {set i 0} {$i < $N} {incr i} {
                set v [pinval $b $i]
                if {$v != [lindex $prev $i]} {
                    puts "[clock format [clock seconds] -format %T] [lindex $pins $i 1] [lindex $pins $i 2] -> $v"
                    flush stdout
                    lset prev $i $v
                }
            }
        }
        puts "# SYSCLK alive bit changed $alive_changes times"
    }
    i2c {
        set ctrl 0
        if {"mclk" in $args} { set ctrl [expr {$ctrl | 0x02}] }
        if {"adr1low" in $args} { set ctrl [expr {$ctrl | 0x10}] }
        shift $ctrl
        after 20
        shift [expr {$ctrl | 1}]
        set t0 [clock milliseconds]
        while 1 {
            after 50
            set b [shift [expr {$ctrl | 1}]]
            if {[field $b 9 1]} break
            if {[clock milliseconds] - $t0 > 5000} { error "scan did not finish: [status $b]" }
        }
        set found {}
        for {set a 0} {$a < 128} {incr a} {
            if {[lindex $b [expr {16 + $N + $a}]]} { lappend found [format 0x%02x $a] }
        }
        puts "# [status $b]"
        if {[llength $found]} { puts "ACK from: [join $found { }]" } else { puts "ACK from: none" }
        shift 0
    }
    hpd {
        set v [lindex $args 0]
        set b [shift [expr {0x40 | ($v ? 0x80 : 0)}]]
        puts "# HPD of HDMI_IN driven $v; the next command releases it"
    }
    default { error "unknown command $cmd" }
}
disconnect
