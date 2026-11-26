#!/usr/bin/env sh
# Builds U-Boot SPL and U-Boot for the PYNQ-Z2: xilinx_zynq_virt_defconfig with zynq-pynq-z2.dts and
# the PS initialization of ps7/build.sh. The environment is kept only in uboot.env on the FAT
# partition of the card, never in the QSPI flash. The FIT images are not signed: the host tools then
# need no libcrypto (OpenSSL 4 has no ENGINE API, which the signing tools of U-Boot use). U-Boot reads
# the MAC address from the OTP area of the QSPI flash (patches/u-boot/). It loads /pl.bit of the FAT
# partition into the PL if the file is there, and sets fdtoverlay_addr_r for the fdtoverlays of
# extlinux.conf. The source tree gets the device tree, its line in the Makefile and the patches; the
# objects go to WORK.
#
#   [WORK=dir] [CROSS_COMPILE=arm-none-eabi-] sh build-uboot.sh /path/to/u-boot /path/to/ps7_init_gpl.c
#
# ps7_init_gpl.c and ps7_init_gpl.h come from ps7/build.sh; the .h must be beside the .c. "none" in
# place of the file builds without the PS initialization: such an SPL cannot start the board, and is
# good only to test the build.
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
    [ -f "$2" ] && [ -f "${2%.c}.h" ] || { echo "need $2 and ${2%.c}.h" >&2; exit 2; }
    # Vivado writes "int ps7_init();", which U-Boot refuses (-Werror=strict-prototypes). A copy in WORK
    # gets "(void)" on the functions without parameters; the export of Vivado stays as it is.
    mkdir -p "$work/ps7"
    sed -E 's/^([a-z][a-z0-9_ ]*[ *]?[A-Za-z_][A-Za-z0-9_]*) ?\(\)/\1(void)/' "$2" > "$work/ps7/ps7_init_gpl.c"
    sed -E 's/^([a-z][a-z0-9_ ]*[ *]?[A-Za-z_][A-Za-z0-9_]*) ?\(\)/\1(void)/' "${2%.c}.h" > "$work/ps7/ps7_init_gpl.h"
    ps7="$work/ps7/ps7_init_gpl.c"
fi

install -m 644 "$here/zynq-pynq-z2.dts" "$src/arch/arm/dts/zynq-pynq-z2.dts"
grep -q 'zynq-pynq-z2.dtb' "$src/arch/arm/dts/Makefile" || sed -i 's/^\(\s*\)zynq-zybo-z7.dtb/\1zynq-pynq-z2.dtb \\\n\1zynq-zybo-z7.dtb/' "$src/arch/arm/dts/Makefile"
grep -q 'zynq-pynq-z2.dtb' "$src/arch/arm/dts/Makefile" || { echo "could not add the dtb to $src/arch/arm/dts/Makefile" >&2; exit 1; }

# A patch that reverses cleanly is in the tree already.
for p in "$here"/patches/u-boot/*.patch; do
    [ -e "$p" ] || continue
    patch -d "$src" -p1 -R -s -f --dry-run <"$p" >/dev/null 2>&1 && continue
    patch -d "$src" -p1 -s -f <"$p" >/dev/null || { echo "could not apply $p" >&2; exit 1; }
done

b="$work/ubuild"
# preboot runs before the boot (docs/pl-interface.md). An uboot.env with a preboot variable takes
# precedence over this default.
# - The default environment of Zynq has no fdtoverlay_addr_r, and extlinux.conf then ignores its
#   fdtoverlays line. 0x1e00000 is 1 MiB below fdt_addr_r (0x1f00000).
# - U-Boot loads pl.bit from the FAT partition into the PL, if the file is there.
# No "&&": scripts/config gives the value to sed, which reads "&" as the matched text.
preboot='env exists fdtoverlay_addr_r || setenv fdtoverlay_addr_r 0x1e00000; if test -e mmc 0:1 /pl.bit; then echo Loading /pl.bit into the PL; if load mmc 0:1 ${kernel_addr_r} /pl.bit; then fpga loadb 0 ${kernel_addr_r} ${filesize}; fi; fi'
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
    --disable TOOLS_LIBCRYPTO \
    --enable ZYNQ_QSPI_OTP_MAC \
    --enable OF_LIBFDT_OVERLAY \
    --enable USE_PREBOOT \
    --set-str PREBOOT "$preboot"
mk olddefconfig >/dev/null
grep -q '^CONFIG_ZYNQ_QSPI_OTP_MAC=y' "$b/.config" || { echo "ZYNQ_QSPI_OTP_MAC is not set" >&2; exit 1; }
grep -q '^CONFIG_OF_LIBFDT_OVERLAY=y' "$b/.config" || { echo "OF_LIBFDT_OVERLAY is not set" >&2; exit 1; }
grep -qxF "CONFIG_PREBOOT=\"$preboot\"" "$b/.config" || { echo "PREBOOT is not set" >&2; exit 1; }
grep -q '^CONFIG_ENV_IS_IN_SPI_FLASH=y' "$b/.config" && { echo "the environment is still in the QSPI flash" >&2; exit 1; }
mk >"$work/build.log" 2>&1 || { tail -20 "$work/build.log" >&2; exit 1; }
cp "$b/spl/boot.bin" "$b/u-boot.img" "$b/u-boot.elf" "$work/"
[ -n "$ps7" ] || echo "warning: built without ps7_init_gpl.c; this boot.bin cannot start the board" >&2
echo "$work: boot.bin, u-boot.img, u-boot.elf"
