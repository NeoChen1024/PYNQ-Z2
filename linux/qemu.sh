#!/usr/bin/env sh
# Boots the kernel and the card image of mkdisk.sh in QEMU (machine xilinx-zynq-a9), on the console of
# this terminal. It tests the kernel, the device tree and the root file system without a board. QEMU
# does not model the board: the Ethernet PHY, the GPIO of the MIO and U-Boot SPL do not work in it.
# Ctrl-A X stops QEMU.
#
#   [WORK=dir] sh qemu.sh /path/to/linux-work /path/to/pynq-z2.img
#
# QEMU needs an SD image with a size of a power of 2: the script uses a copy, WORK/qemu-sd.img
# (./pynq-qemu by default), and leaves the image of mkdisk.sh as it is.
set -eu
[ $# -eq 2 ] && [ -f "$1/zImage" ] && [ -f "$2" ] || { echo "usage: sh qemu.sh /path/to/linux-work /path/to/pynq-z2.img" >&2; exit 2; }
mkdir -p "${WORK:-pynq-qemu}"
work="$(cd "${WORK:-pynq-qemu}" && pwd)"
size="$(stat -c %s "$2")"
p=1
while [ "$p" -lt "$size" ]; do p=$((p * 2)); done
cp "$2" "$work/qemu-sd.img"
truncate -s "$p" "$work/qemu-sd.img"
exec qemu-system-arm -M xilinx-zynq-a9 -m 512M -nographic \
    -kernel "$1/zImage" -dtb "$1/zynq-pynq-z2.dtb" \
    -append "console=ttyPS0,115200 root=/dev/mmcblk0p2 rootfstype=f2fs rootwait rw" \
    -drive file="$work/qemu-sd.img",if=sd,format=raw -serial mon:stdio
