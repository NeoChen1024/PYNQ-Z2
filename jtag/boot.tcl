# Boots the PS over JTAG: resets the system, runs ps7_init (clocks, MIO, DDR), loads an optional
# bitstream into the PL, loads data files into the DDR and an ELF program, and starts it. Nothing is
# written to the QSPI flash or the card. The board must be in JTAG boot mode (docs/boot.md).
#
#   xsdb boot.tcl <ps7_init.tcl> <program.elf> [bitstream|-] [file@address ...]
set data [lassign $argv init elf bit]
connect
targets -set -nocase -filter {name =~ "APU*"}
rst -system
after 1000
targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
source $init
ps7_init
if {$bit ne "" && $bit ne "-"} {
    targets -set -nocase -filter {name =~ "xc7z020*"}
    fpga -file $bit
    targets -set -nocase -filter {name =~ "*Cortex-A9*#0"}
}
# Turns on the level shifters between the PS and the PL.
ps7_post_config
foreach item $data {
    lassign [split $item @] file address
    dow -data $file $address
    puts "loaded $file at $address"
}
dow $elf
con
puts "started $elf"
set ::release_only 1
source [file join [file dirname [info script]] release.tcl]
release_cores
disconnect
