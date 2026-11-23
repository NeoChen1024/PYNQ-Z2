#!/usr/bin/env sh
# Builds pl-blinky for the PYNQ-Z2 with Vivado.
#
#   [VIVADO=/path/to/vivado] [WORK=dir] sh build.sh
#
# Everything is written under WORK, ./pynq-blinky in the current directory by default: the reports
# and blinky.bit in WORK/build. Load the bitstream with ../../jtag/load.sh.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
vivado="${VIVADO:-vivado}"
mkdir -p "${WORK:-pynq-blinky}"
work="$(cd "${WORK:-pynq-blinky}" && pwd)"
out="$work/build"
rm -rf "$out"
mkdir -p "$out"
cd "$out"
top=pynq_z2_blinky
"$vivado" -mode batch -nojournal -log build.log -source "$here/build.tcl" \
    -tclargs "$top" xc7z020clg400-1 "$here/blinky.xdc" "$here/blinky.sv" >build.out 2>&1 </dev/null || true
if [ ! -f "$top.bit" ]; then
    echo "Vivado failed; see $out/build.log" >&2
    grep -E '^ERROR' build.log | head -5 >&2 || true
    exit 1
fi
mv "$top.bit" blinky.bit
# Timing that is not met still makes a bitstream: say so, and let the caller decide.
awk '/WNS\(ns\) +TNS\(ns\)/ { getline; getline; printf "setup slack %s ns, hold slack %s ns, pulse width slack %s ns\n", $1, $5, $9; exit }' timing.rpt
if grep -q 'Timing constraints are not met' timing.rpt; then
    echo "timing is not met; see $out/timing.rpt" >&2
    exit 3
fi
echo "$out/blinky.bit"
