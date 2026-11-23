# Linux on the PYNQ-Z2

The PS boots U-Boot SPL, U-Boot and a mainline kernel, with an Alpine Linux root file system on F2FS
on the card. No Vitis FSBL and no PetaLinux are used. The PL is free for the designs of the user.

**Status:** nothing of this has run on a board yet. The SPL needs `ps7_init_gpl.c` from
`ps7/build.sh`, which needs the Zynq-7000 devices in Vivado.

On 2026-11-23 the kernel, the device tree and the root file system booted in QEMU (`qemu.sh`, QEMU
machine `xilinx-zynq-a9`) to the login prompt. In QEMU, the root F2FS mounted, mdev loaded
`i2c_gpio`, the QSPI flash showed as the read-only `mtd0`, sshd and chronyd started, and `poweroff`
halted the system. QEMU is not the board: its Ethernet PHY and the GPIO of the MIO do not behave
as on the board, and U-Boot SPL was not run.

| Part | Version | Source |
|---|---|---|
| U-Boot | v2026.10 | <https://source.denx.de/u-boot/u-boot.git>, tag `v2026.10` |
| Linux | 6.18.64 (longterm) | <https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.64.tar.xz> |
| Alpine Linux | 3.24.4, armv7 | The `alpine:3.24.4` container and <https://dl-cdn.alpinelinux.org/alpine/v3.24/> |

The sources stay outside the repository. The build scripts add only `zynq-pynq-z2.dts` and its line
in the Makefile of the device trees to each source tree.

## Files

| File | Contents |
|---|---|
| `zynq-pynq-z2.dts` | The device tree of the board, for U-Boot and Linux: UART0, GEM0 with the PHY at MDIO address 1, SDIO0, USB0 as host, the QSPI flash (read-only), the HDMI output DDC on MIO50/51 |
| `pynq-z2.config` | The kernel configuration fragment, on top of `multi_v7_defconfig` |
| `build-kernel.sh` | Builds `zImage`, the device tree and the modules with clang (`LLVM=1`) |
| `build-uboot.sh` | Builds `boot.bin` (the SPL with the boot header), `u-boot.img` and `u-boot.elf` with `arm-none-eabi-gcc` |
| `mkrootfs.sh` | Makes `rootfs.f2fs` in an armv7 Alpine container |
| `mkdisk.sh` | Makes the image of a card from the outputs of the three scripts above. It does not write a card |
| `qemu.sh` | Boots the kernel and the card image in QEMU, without U-Boot |

## Build

The host needs clang and lld, `arm-none-eabi-gcc`, docker with qemu-user binfmt for ARM (F flag),
mtools and f2fs-tools.

```sh
P=/path/to/this/repository
export VIVADO=/path/to/Xilinx/2025.2.1/Vivado/bin/vivado
cd /some/writable/directory

sh $P/ps7/build.sh                                        # ./pynq-ps7: ps7_init_gpl.c, ps7_init.tcl
sh $P/linux/build-uboot.sh /path/to/u-boot pynq-ps7/ps7_init_gpl.c     # ./pynq-uboot
sh $P/linux/build-kernel.sh /path/to/linux-6.18.64                     # ./pynq-linux
sh $P/linux/mkrootfs.sh /path/to/key.pub pynq-linux/modules            # ./pynq-rootfs/rootfs.f2fs
sh $P/linux/mkdisk.sh pynq-uboot pynq-linux pynq-rootfs/rootfs.f2fs    # ./pynq-disk/pynq-z2.img
```

Each script gives its options at its start. A JTAG boot (`jtag/boot.sh`) can start `u-boot.elf`
without a card in the boot path.

## The system

- U-Boot keeps its environment in `uboot.env` on the FAT partition. It never writes the QSPI flash.
  The FIT images are not signed.
- U-Boot reads `extlinux/extlinux.conf` from the FAT partition. The kernel command line has
  `console=ttyPS0,115200 root=/dev/mmcblk0p2 rootfstype=f2fs`.
- The MAC address is random for each boot of U-Boot (`CONFIG_NET_RANDOM_ETHADDR`). The unique
  identifier in the OTP area of the QSPI flash is not used (docs/boot.md).
- Alpine runs OpenRC with busybox, sshd (only the key of `mkrootfs.sh`), chrony, and DHCP on `eth0`.
  Root has no password on the console `ttyPS0`.
- The QSPI flash is one read-only partition in Linux.
- The device tree gives the CPU the operating points 650 MHz and 325 MHz, the divisors 2 and 4 of the
  ARM PLL of the board preset. With the 666667 kHz of `zynq-7000.dtsi`, the start frequency is not in
  the table; cpufreq-dt then tries to change it, fails, and stops the kernel at a `BUG_ON` (seen in
  QEMU on 2026-11-23).
- `i2c-gpio` (the HDMI output DDC) is a module. If SCL stays low, its probe waits for about 18 s; in
  QEMU it held the boot for that time while it was built in.

## Not yet confirmed

These choices follow the documents and must be checked on the board:

- `phy-mode = "rgmii-id"`, which assumes that the TXDLY and RXDLY straps of the RTL8211E add the
  delays (docs/ethernet.md).
- The card detect on MIO47: its polarity is not known (docs/sd-card.md).
- The reset of the USB PHY on MIO46 and the reset of the Ethernet PHY on MIO9 (`reset-gpios`).
- Whether cpufreq changes the CPU between 650 MHz and 325 MHz on the board. In QEMU it changed from
  250 MHz (the start frequency of QEMU) to 325 MHz.
