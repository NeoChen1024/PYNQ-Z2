# Linux on the PYNQ-Z2

The PS boots U-Boot SPL, U-Boot and a mainline kernel, with an Alpine Linux root file system on F2FS
on the card. No Vitis FSBL and no PetaLinux are used. The PL is free for the designs of the user.

**Status:** the system runs on the board **[measured]**. On 2026-11-24, the card image of
`mkdisk.sh` booted from a 64 GB microSD card (JP1 in the SD position) to the login prompt:

- The boot ROM loaded U-Boot SPL from `BOOT.BIN`. The SPL ran `ps7_init` and loaded `u-boot.img`.
- U-Boot found 512 MiB of DRAM, read `extlinux.conf` and started the kernel.
- The kernel mounted the root F2FS. OpenRC started mdev, the network, chronyd and sshd.
- `eth0` linked at 1000 Mb/s full duplex. DHCP, NTP and SSH worked, with 0 receive and 0 transmit
  errors.
- The card ran in SD High Speed mode, 50 MHz, 4 bits. A read of 256 MiB of `mmcblk0p2` with
  `dd bs=1M iflag=direct` took 12.6 s: 20.3 MB/s. The card was a 64 GB card, `SB64G`.
- cpufreq (`ondemand`) used both operating points, 650 MHz and 325 MHz.
- The QSPI flash showed as the read-only `mtd0` (16 MiB).
- The USB host found a USB flash drive at boot (`usb-storage`), with the patch of `patches/linux/`
  (see below).

Before the board, the system booted in QEMU (`qemu.sh`, QEMU machine `xilinx-zynq-a9`) on
2026-11-23. `qemu.sh` stays for tests of the kernel and the root file system without the board.

| Part | Version | Source |
|---|---|---|
| U-Boot | v2026.10 | <https://source.denx.de/u-boot/u-boot.git>, tag `v2026.10` |
| Linux | 6.18.64 (longterm) | <https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.64.tar.xz> |
| Alpine Linux | 3.24.4, armv7 | The `alpine:3.24.4` container and <https://dl-cdn.alpinelinux.org/alpine/v3.24/> |

The sources stay outside the repository. The build scripts add `zynq-pynq-z2.dts` and its line in
the Makefile of the device trees to each source tree. `build-kernel.sh` applies the patches of
`patches/linux/`, and `build-uboot.sh` the patches of `patches/u-boot/`.

## Files

| File | Contents |
|---|---|
| `zynq-pynq-z2.dts` | The device tree of the board, for U-Boot and Linux: UART0, GEM0 with the PHY at MDIO address 1, SDIO0, USB0 as host, the QSPI flash (read-only), the HDMI output DDC on MIO50/51 |
| `pynq-z2.config` | The kernel configuration fragment, on top of `multi_v7_defconfig` |
| `patches/linux/`, `patches/u-boot/` | Patches to Linux and to U-Boot, applied by the build scripts (GPL-2.0, as Linux and U-Boot) |
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
- U-Boot reads the MAC address from the OTP area of the QSPI flash, offset 0x20 (docs/boot.md),
  and gives it to Linux in the device tree. `patches/u-boot/` adds this (`CONFIG_ZYNQ_QSPI_OTP_MAC`).
  It only reads the OTP area. An `ethaddr` in `uboot.env` takes precedence. If the OTP area has no
  valid address, U-Boot makes a random one (`CONFIG_NET_RANDOM_ETHADDR`).
- Alpine runs OpenRC with busybox, sshd (only the key of `mkrootfs.sh`), chrony, and DHCP on `eth0`.
  Root has no password on the console `ttyPS0`.
- The QSPI flash is one read-only partition in Linux.
- The device tree gives the CPU the operating points 650 MHz and 325 MHz, the divisors 2 and 4 of the
  ARM PLL of the board preset. With the 666667 kHz of `zynq-7000.dtsi`, the start frequency is not in
  the table; cpufreq-dt then tries to change it, fails, and stops the kernel at a `BUG_ON` (seen in
  QEMU on 2026-11-23).
- `i2c-gpio` (the HDMI output DDC) is a module. If SCL stays low, its probe waits for about 18 s; in
  QEMU it held the boot for that time while it was built in.

## USB host

Mainline Linux 6.18 does not turn on the VBUS of the USB port of this board. Two changes make the
port work **[measured]** 2026-11-24:

- The USB0 node uses `phys`, not the old `usb-phy`. The ChipIdea driver looks up only `phys`. With
  `usb-phy`, it probed before the PHY driver, failed with `-ENXIO` and printed no message.
- `patches/linux/0001-usb-chipidea-host-drive-external-VBUS-of-a-ULPI-PHY.patch` sets `DrvVbus` and
  `DrvVbusExternal` in the OTG Control register of the ULPI PHY when the port power changes.

The TUSB1210 drives `CPEN`, the enable of the VBUS switch U10, only with `DrvVbusExternal` set
(docs/usb.md). `usb-nop-xceiv` does not set it, and the TUSB1210 PHY driver of Linux does not
connect to the ChipIdea driver. Without the patch, the controller runs, but VBUS stays off and the
port finds no device.

## MAC address

U-Boot v2026.10 has no code that reads the MAC address of this board, and it made a random address
at each boot. `patches/u-boot/0001-net-zynq_gem-read-the-MAC-address-from-the-QSPI-OTP.patch` adds
`read_rom_hwaddr` to the GEM driver. With `CONFIG_ZYNQ_QSPI_OTP_MAC`, it sends OTP Read (0x4B) to
the QSPI flash and reads 6 bytes at offset 0x20. On 2026-11-24 **[measured]**:

- U-Boot printed no random address, and `ethaddr` was equal to the OTP bytes 0x20 to 0x25.
- Linux used the same address (`macb ... eth0`), and DHCP gave the same lease after a reboot.

## Checked on the board

These choices followed the documents. The boot of 2026-11-24 confirmed them **[measured]**:

- `phy-mode = "rgmii-id"`: the link ran at 1000 Mb/s with traffic and no errors (docs/ethernet.md).
- The card detect on MIO47 without `cd-inverted`: U-Boot found no card in an empty slot, and found
  the card when it was in the slot (docs/sd-card.md).
- The PHY resets on MIO9 and MIO46 (`reset-gpios`): both PHYs worked after Linux released them.
- The operating points 650 MHz and 325 MHz: cpufreq changed between them.
- Both cores run, after a power-on and after a reboot. If Linux prints `CPU1: failed to come
  online`, a JTAG session left the reset vector catch set: run `xsdb jtag/release.tcl reset`, or
  switch the power off and on (docs/jtag-uart.md).
