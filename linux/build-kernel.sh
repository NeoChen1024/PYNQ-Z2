#!/usr/bin/env sh
# Builds Linux for the PYNQ-Z2 with clang (LLVM=1, so no ARM gcc is needed): multi_v7_defconfig with
# pynq-z2.config, zynq-pynq-z2.dts and the patches of patches/linux/. The source tree gets the device tree,
# its line in the Makefile and the patches; the objects go to WORK.
#
#   [WORK=dir] sh build-kernel.sh /path/to/linux-6.18
#
# Writes into WORK, ./pynq-linux in the current directory by default: kbuild/ (the objects and
# .config), zImage, zynq-pynq-z2.dtb and modules/lib/modules.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 1 ] && [ -f "$1/Makefile" ] || { echo "usage: sh build-kernel.sh /path/to/linux" >&2; exit 2; }
src="$(cd "$1" && pwd)"
renice -n 19 -p $$ >/dev/null 2>&1 || true
mkdir -p "${WORK:-pynq-linux}"
work="$(cd "${WORK:-pynq-linux}" && pwd)"

dts="$src/arch/arm/boot/dts/xilinx"
install -m 644 "$here/zynq-pynq-z2.dts" "$dts/zynq-pynq-z2.dts"
grep -q 'zynq-pynq-z2.dtb' "$dts/Makefile" || sed -i 's/^\(\s*\)zynq-zybo-z7.dtb/\1zynq-pynq-z2.dtb \\\n\1zynq-zybo-z7.dtb/' "$dts/Makefile"
grep -q 'zynq-pynq-z2.dtb' "$dts/Makefile" || { echo "could not add the dtb to $dts/Makefile" >&2; exit 1; }
# -@ keeps the labels in the dtb, so that an overlay of fdtoverlays can refer to them (docs/pl-interface.md).
grep -q '^DTC_FLAGS_zynq-pynq-z2' "$dts/Makefile" || echo 'DTC_FLAGS_zynq-pynq-z2 := -@' >>"$dts/Makefile"

# A patch that reverses cleanly is in the tree already.
for p in "$here"/patches/linux/*.patch; do
    [ -e "$p" ] || continue
    patch -d "$src" -p1 -R -s -f --dry-run <"$p" >/dev/null 2>&1 && continue
    patch -d "$src" -p1 -s -f <"$p" >/dev/null || { echo "could not apply $p" >&2; exit 1; }
done

k="$work/kbuild"
mk() { make -C "$src" O="$k" ARCH=arm LLVM=1 -j"$(nproc)" "$@"; }
mk multi_v7_defconfig >/dev/null
"$src/scripts/kconfig/merge_config.sh" -m -O "$k" "$k/.config" "$here/pynq-z2.config" >/dev/null
mk olddefconfig >/dev/null
# merge_config.sh only warns when a value of the fragment does not survive.
fail=0
while IFS= read -r line; do
    case "$line" in CONFIG_*) grep -qxF "$line" "$k/.config" || { echo "not in .config: $line" >&2; fail=1; } ;; esac
done < "$here/pynq-z2.config"
[ "$fail" -eq 0 ] || exit 1

mk zImage dtbs modules >"$work/build.log" 2>&1 || { tail -20 "$work/build.log" >&2; exit 1; }
rm -rf "$work/modules"
mk INSTALL_MOD_PATH="$work/modules" INSTALL_MOD_STRIP=1 modules_install >/dev/null
cp "$k/arch/arm/boot/zImage" "$work/zImage"
cp "$k/arch/arm/boot/dts/xilinx/zynq-pynq-z2.dtb" "$work/zynq-pynq-z2.dtb"
echo "$work: zImage, zynq-pynq-z2.dtb, modules/lib/modules/$(cat "$k/include/config/kernel.release")"
