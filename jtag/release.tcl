# Leaves the Cortex-A9 cores as a power-on reset leaves them: no reset vector catch.
#
#   xsdb release.tcl [reset]        "reset" then also resets the system (as the SRST button)
#
# When hw_server connects, it sets the reset vector catch (DBGVCR bit 0) of both cores, and it sets
# it again while it has access to them. The bit stays after the disconnect, until a power-on reset.
# A core that resets later then stops at its reset vector: Linux, which resets CPU1 to start it, then
# runs on one core only, and a reboot stops. Thus each script of this repository that connects to the
# board calls release_cores before it disconnects. Other scripts source this file with
# ::release_only set, to get the procedure only.
proc release_cores {} {
    foreach t [targets -target-properties] {
        if {[string match "*Cortex-A9*" [dict get $t name]]} {
            configparams -target-id [dict get $t target_id] disable-access 1
        }
    }
    targets -set -nocase -filter {name =~ "APU*"}
    # DBGVCR of CPU0 and CPU1, in the memory-mapped debug registers.
    foreach a {0xF889001C 0xF889201C} { mwr -force $a 0 }
}
if {![info exists ::release_only]} {
    connect
    release_cores
    if {[lindex $argv 0] eq "reset"} {
        # A soft reset through the SLCR (unlock, then PSS_RST_CTRL), the same as a reboot of Linux.
        mwr -force 0xF8000008 0xDF0D
        catch {mwr -force 0xF8000200 1}
    }
    disconnect
}
