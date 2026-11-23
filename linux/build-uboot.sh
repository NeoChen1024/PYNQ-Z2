#!/usr/bin/env sh
# Builds U-Boot SPL and U-Boot for the PYNQ-Z2: xilinx_zynq_virt_defconfig with zynq-pynq-z2.dts and
# the PS initialization of ps7/build.sh. The environment is kept only in uboot.env on the FAT
# partition of the card, never in the QSPI flash. The FIT images are not signed: the host tools then
# need no libcrypto (OpenSSL 4 has no ENGINE API, which the signing tools of U-Boot use). The source tree gets only the device tree and its
# line in the Makefile; the objects go to WORK.
#
#   [WORK=dir] [CROSS_COMPILE=arm-none-eabi-] sh build-uboot.sh /path/to/u-boot /path/to/ps7_init_gpl.c
#
# ps7_init_gpl.h must be beside ps7_init_gpl.c. "none" in place of the file builds without the PS
# initialization: such an SPL cannot start the board, and is good only to test the build.
# Writes into WORK, ./pynq-uboot in the current directory by default: ubuild/ (the objects),
# boot.bin (the boot image with the SPL), u-boot.img (U-Boot for the SPL) and u-boot.elf (for
# jtag/boot.sh).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 2 ] && [ -f "$1/Makefile" ] || { echo "usage: sh build-uboot.sh /path/to/u-boot ps7_init_gpl.c|none" >&2; exit 2; }
src="$(cd "$1" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
mkdir -p "${WORK:-pynq-uboot}"
work="$(cd "${WORK:-pynq-uboot}" && pwd)"
export CROSS_COMPILE="${CROSS_COMPILE:-arm-none-eabi-}"

ps7=""
if [ "$2" != none ]; then
    ps7="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
    [ -f "$ps7" ] && [ -f "${ps7%.c}.h" ] || { echo "need $2 and ${2%.c}.h" >&2; exit 2; }
fi

install -m 644 "$here/zynq-pynq-z2.dts" "$src/arch/arm/dts/zynq-pynq-z2.dts"
grep -q 'zynq-pynq-z2.dtb' "$src/arch/arm/dts/Makefile" || sed -i 's/^\(\s*\)zynq-zybo-z7.dtb/\1zynq-pynq-z2.dtb \\\n\1zynq-zybo-z7.dtb/' "$src/arch/arm/dts/Makefile"
grep -q 'zynq-pynq-z2.dtb' "$src/arch/arm/dts/Makefile" || { echo "could not add the dtb to $src/arch/arm/dts/Makefile" >&2; exit 1; }

b="$work/ubuild"
mk() { make -C "$src" O="$b" -j"$(nproc)" "$@"; }
mk xilinx_zynq_virt_defconfig >/dev/null
"$src/scripts/config" --file "$b/.config" \
    --set-str DEFAULT_DEVICE_TREE zynq-pynq-z2 \
    --set-str OF_LIST zynq-pynq-z2 \
    --set-str XILINX_PS_INIT_FILE "$ps7" \
    --disable ENV_IS_IN_SPI_FLASH \
    --disable ENV_IS_IN_NAND \
    --enable ENV_IS_IN_FAT \
    --set-str ENV_FAT_INTERFACE mmc \
    --set-str ENV_FAT_DEVICE_AND_PART 0:1 \
    --disable FIT_SIGNATURE \
    --disable SPL_FIT_SIGNATURE \
    --disable TOOLS_KWBIMAGE \
    --disable TOOLS_LIBCRYPTO
mk olddefconfig >/dev/null
grep -q '^CONFIG_ENV_IS_IN_SPI_FLASH=y' "$b/.config" && { echo "the environment is still in the QSPI flash" >&2; exit 1; }
mk >"$work/build.log" 2>&1 || { tail -20 "$work/build.log" >&2; exit 1; }
cp "$b/spl/boot.bin" "$b/u-boot.img" "$b/u-boot.elf" "$work/"
[ -n "$ps7" ] || echo "warning: built without ps7_init_gpl.c; this boot.bin cannot start the board" >&2
echo "$work: boot.bin, u-boot.img, u-boot.elf"
