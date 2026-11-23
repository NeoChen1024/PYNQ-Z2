#!/usr/bin/env sh
# Loads a bitstream into the PL of the PYNQ-Z2 over the USB-JTAG of the board (J8). It is gone at
# power-off, and no flash or card is touched. The logs (load.log, load.out) go beside the bitstream.
#
#   [VIVADO=/path/to/vivado] sh load.sh design.bit
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 1 ] && [ -f "$1" ] || { echo "usage: sh load.sh design.bit" >&2; exit 2; }
bit="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
vivado="${VIVADO:-vivado}"
cd "$(dirname "$bit")"
status=0
"$vivado" -mode batch -nojournal -log load.log -source "$here/load.tcl" -tclargs "$bit" >load.out 2>&1 </dev/null || status=$?
# Vivado leaves its servers running.
pkill -u "$(id -u)" -x hw_server 2>/dev/null || true
pkill -u "$(id -u)" -x cs_server 2>/dev/null || true
if [ "$status" -ne 0 ] || ! grep -q '^DONE=1' load.out; then
    echo "load failed; see $(pwd)/load.log" >&2
    exit 1
fi
echo "loaded $bit"
