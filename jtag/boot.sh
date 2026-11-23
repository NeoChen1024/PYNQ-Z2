#!/usr/bin/env sh
# Boots the PS of the PYNQ-Z2 over the USB-JTAG of the board, without the QSPI flash or a card: see
# boot.tcl. Put JP1 in the JTAG position first (docs/boot.md). ps7_init.tcl comes from ps7/build.sh.
#
#   [XSDB=/path/to/xsdb] sh boot.sh ps7_init.tcl program.elf [bitstream|-] [file@address ...]
#
# For example U-Boot with a kernel, a device tree and an initramfs in the DDR (linux/README.md):
#   sh boot.sh ps7_init.tcl u-boot.elf - zImage@0x2080000 pynq-z2.dtb@0x2000000 initramfs.uImage@0x4000000
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -ge 2 ] || { echo "usage: sh boot.sh ps7_init.tcl program.elf [bitstream|-] [file@address ...]" >&2; exit 2; }
"${XSDB:-xsdb}" "$here/boot.tcl" "$@"
pkill -u "$(id -u)" -x hw_server 2>/dev/null || true
