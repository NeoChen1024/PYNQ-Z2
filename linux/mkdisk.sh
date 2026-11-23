#!/usr/bin/env sh
# Makes the image of a card for the PYNQ-Z2 (linux/README.md), as a file: it does not write a card.
#
#   [WORK=dir] [ROOT_SIZE=3G] sh mkdisk.sh /path/to/uboot-work /path/to/linux-work /path/to/rootfs.f2fs
#
# The two work directories are those of build-uboot.sh (boot.bin, u-boot.img) and build-kernel.sh
# (zImage, zynq-pynq-z2.dtb). Writes WORK/pynq-z2.img, ./pynq-disk in the current directory by default:
#   p1  FAT32, 64 MiB, label BOOT: BOOT.BIN (the boot ROM loads the SPL from it), u-boot.img, zImage,
#       zynq-pynq-z2.dtb and extlinux/extlinux.conf, which U-Boot reads
#   p2  the root file system, grown to ROOT_SIZE (F2FS; resize.f2fs fills the partition)
# The host needs mtools and f2fs-tools.
# Write the image to a card only with the owner's permission for that card (AGENTS.md), for example
# with dd and the card's device, after a check that the device is the card.
set -eu
[ $# -eq 3 ] && [ -f "$1/boot.bin" ] && [ -f "$2/zImage" ] && [ -f "$3" ] || {
    echo "usage: sh mkdisk.sh /path/to/uboot-work /path/to/linux-work /path/to/rootfs.f2fs" >&2; exit 2; }
uboot="$(cd "$1" && pwd)"
linux="$(cd "$2" && pwd)"
rootfs="$3"
mkdir -p "${WORK:-pynq-disk}"
work="$(cd "${WORK:-pynq-disk}" && pwd)"
img="$work/pynq-z2.img"

boot_mib=64
root_bytes="$(numfmt --from=iec "${ROOT_SIZE:-3G}")"
[ "$root_bytes" -ge "$(stat -c %s "$rootfs")" ] || { echo "ROOT_SIZE is smaller than $rootfs" >&2; exit 2; }

# The boot partition.
fat="$work/boot.vfat"
rm -f "$fat"
mkfs.fat -C -F 32 -n BOOT "$fat" $((boot_mib * 1024)) >/dev/null
cat >"$work/extlinux.conf" <<'CONF'
default pynq-z2
timeout 3
label pynq-z2
    kernel /zImage
    fdt /zynq-pynq-z2.dtb
    append console=ttyPS0,115200 root=/dev/mmcblk0p2 rootfstype=f2fs rootwait rw
CONF
mcopy -i "$fat" "$uboot/boot.bin" ::BOOT.BIN
mcopy -i "$fat" "$uboot/u-boot.img" "$linux/zImage" "$linux/zynq-pynq-z2.dtb" ::
mmd -i "$fat" ::extlinux
mcopy -i "$fat" "$work/extlinux.conf" ::extlinux/extlinux.conf

# The root partition: the file system, grown to the size of the partition.
root="$work/root.f2fs"
cp "$rootfs" "$root"
truncate -s "$root_bytes" "$root"
# -F answers the question of resize.f2fs (1.17 asks before it resizes).
resize.f2fs -F "$root" >/dev/null
fsck.f2fs "$root" >/dev/null

# MBR: p1 at 1 MiB, type c (FAT32 LBA), bootable; p2 after it, type 83.
rm -f "$img"
truncate -s $(( (1 + boot_mib) * 1048576 + root_bytes )) "$img"
sfdisk -q "$img" <<EOF
label: dos
start=2048, size=$((boot_mib * 2048)), type=c, bootable
start=$(( (1 + boot_mib) * 2048 )), size=$((root_bytes / 512)), type=83
EOF
dd if="$fat" of="$img" bs=1M seek=1 conv=notrunc status=none
dd if="$root" of="$img" bs=1M seek=$((1 + boot_mib)) conv=notrunc status=none
rm -f "$fat" "$root" "$work/extlinux.conf"
echo "$img"
