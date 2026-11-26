#!/usr/bin/env sh
# Builds pl-interface, the test design of docs/pl-interface.md, with Vivado.
#
#   [VIVADO=/path/to/vivado] [WORK=dir] sh build.sh
#
# Everything is written under WORK, ./pynq-pl-interface in the current directory by default: the
# reports and pl_interface.bit in WORK/build. Load the bitstream with ../../jtag/load.sh, or copy it to
# the FAT partition of the card as pl.bit (U-Boot then loads it at boot). pltest.c tests it from Linux.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
vivado="${VIVADO:-vivado}"
mkdir -p "${WORK:-pynq-pl-interface}"
work="$(cd "${WORK:-pynq-pl-interface}" && pwd)"
out="$work/build"
rm -rf "$out"
mkdir -p "$out"
cd "$out"
top=pynq_z2_pl_interface
"$vivado" -mode batch -nojournal -log build.log -source "$here/build.tcl" \
    -tclargs "$top" xc7z020clg400-1 "$here/pl_interface.xdc" "$here/pl_interface.sv" >build.out 2>&1 </dev/null || true
if [ ! -f "$top.bit" ]; then
    echo "Vivado failed; see $out/build.log" >&2
    grep -E '^ERROR' build.log | head -5 >&2 || true
    exit 1
fi
mv "$top.bit" pl_interface.bit
awk '/WNS\(ns\) +TNS\(ns\)/ { getline; getline; printf "setup slack %s ns, hold slack %s ns, pulse width slack %s ns\n", $1, $5, $9; exit }' timing.rpt
# Vivado writes the bitstream also when timing fails: such a bitstream is not used.
if grep -q 'Timing constraints are not met' timing.rpt; then
    echo "timing is not met; see $out/timing.rpt" >&2
    rm -f pl_interface.bit
    exit 3
fi
echo "$out/pl_interface.bit"
