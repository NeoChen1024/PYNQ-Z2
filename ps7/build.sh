#!/usr/bin/env sh
# Exports the PS7 configuration of the board preset (docs/ps.md) with Vivado.
#
#   [VIVADO=/path/to/vivado] [WORK=dir] sh build.sh
#
# Writes into WORK, ./pynq-ps7 in the current directory by default: pynq-z2.xsa, ps7_init_gpl.c,
# ps7_init_gpl.h, ps7_init.tcl and ps7_init.html, and the Vivado project in WORK/proj. U-Boot SPL
# (linux/build-uboot.sh) takes ps7_init_gpl.c; a JTAG boot (jtag/boot.sh) takes ps7_init.tcl.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
vivado="${VIVADO:-vivado}"
mkdir -p "${WORK:-pynq-ps7}"
work="$(cd "${WORK:-pynq-ps7}" && pwd)"
cd "$work"
rm -f ps7_init_gpl.c ps7_init_gpl.h ps7_init.tcl ps7_init.html pynq-z2.xsa
"$vivado" -mode batch -nojournal -log ps7.log -source "$here/ps7.tcl" \
    -tclargs "$here/../board-files" >ps7.out 2>&1 </dev/null || true
if [ ! -f ps7_init_gpl.c ] || [ ! -f pynq-z2.xsa ]; then
    echo "Vivado failed; see $work/ps7.log" >&2
    grep -E '^ERROR' ps7.log | head -5 >&2 || true
    exit 1
fi
echo "$work"
