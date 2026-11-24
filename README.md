# TUL PYNQ-Z2 board notes

This repository records what is known about the TUL PYNQ-Z2 board (Xilinx XC7Z020-1CLG400C). It has
the pins, the clocks, the boot, the PS configuration and the peripherals, with their sources and the
faults that were found in the vendor files. A project that uses this board can take these files as
they are. It also keeps the vendor documents and the Vivado board files, because their links stopped
working.

The XC7Z020 has a PS with two Cortex-A9 cores. The Linux work uses that PS with U-Boot, a mainline
kernel and Alpine Linux. A soft CPU in the PL is not part of this record.

Each statement has one of four sources. The text marks them:

| Mark | Meaning |
|---|---|
| **[measured]** | A design ran on this board and showed it, or an instrument measured it |
| **[schematic]** | From the TUL schematic (`references/tul/TUL_PYNQ_Schematic_R12.pdf`), with the sheet |
| **[manual]** | From the TUL PYNQ-Z2 Reference Manual v1.0 only |
| **[package]** | Checked against the `xc7z020clg400` package data of Vivado |

If no source says something, the text says that it is not known.

## The board

| Part | Summary | Details |
|---|---|---|
| FPGA | XC7Z020-1CLG400C: two Cortex-A9 cores and the PL. Built as -1 | [docs/fpga.md](docs/fpga.md) |
| Power | Micro-USB or a 7 V to 15 V jack, selected by J9; TPS65400 regulators | [docs/power.md](docs/power.md) |
| Clocks | 50 MHz `PS_CLK`; 125 MHz `SYSCLK` on H16 comes from the Ethernet PHY | [docs/clocks.md](docs/clocks.md) |
| Boot | JP1 selects JTAG, QSPI or SD boot; a Quad SPI flash on MIO1 to MIO6 | [docs/boot.md](docs/boot.md) |
| JTAG and UART | One micro-USB (FT2232H) gives the JTAG and the PS UART on MIO14/15 | [docs/jtag-uart.md](docs/jtag-uart.md) |
| PS | The MIO table, 512 MiB of DDR3 on 16 bits (a DDR3L part at 1.5 V), the two PS7 presets | [docs/ps.md](docs/ps.md) |
| Ethernet | Gigabit, RTL8211E-VL on GEM0 (RGMII, MIO16 to MIO27) | [docs/ethernet.md](docs/ethernet.md) |
| USB | Host port on USB0 through a TUSB1210 ULPI PHY | [docs/usb.md](docs/usb.md) |
| SD card | microSD on SDIO0 (MIO40 to MIO47) through a level shifter | [docs/sd-card.md](docs/sd-card.md) |
| HDMI | Input and output; the TMDS pairs go directly to the PL | [docs/hdmi.md](docs/hdmi.md) |
| Audio | ADAU1761 codec; the PL gives its master clock | [docs/audio.md](docs/audio.md) |
| Headers | 2 Pmod, Raspberry Pi 40-pin, Arduino. PmodA shares its pins with the Raspberry Pi header | [docs/headers.md](docs/headers.md) |
| LEDs, buttons, switches | 4 LEDs, 2 RGB LEDs, 4 buttons, 2 switches on the PL | [docs/leds-buttons-switches.md](docs/leds-buttons-switches.md) |
| Crypto chip | ATSHA204A on J15, possibly not fitted | [docs/crypto.md](docs/crypto.md) |
| Vivado | The master XDC, the board files, and the faults of the vendor files | [docs/vivado.md](docs/vivado.md) |
| Not known | The open questions | [docs/unknowns.md](docs/unknowns.md) |

Read these points before you use the board:

- **No header pin is 5 V tolerant** (docs/headers.md).
- **PmodA and the Raspberry Pi header share eight pins.** Use one of them at a time.
- **The 125 MHz `SYSCLK` stops while the Ethernet PHY is in reset** (MIO9).
- **The TUL XDC and the board file have faults.** Use `pynq_z2_master.xdc` (docs/vivado.md).
- Few statements are measured yet. A statement without **[measured]** comes from a document.

## Files

| File | Contents |
|---|---|
| `docs/` | The description of the board, one file for each part (the table above) |
| `AGENTS.md` | The rules for work on this repository |
| `LICENSE` | The MIT License, which applies to the files that the owner wrote (see below) |
| `pins.csv` | Each FPGA pin that the schematic connects (PL and PS): bank, VCCO, function, net, port, I/O standard, the names in the TUL XDC and in the board file, and notes |
| `pynq_z2_master.xdc` | Master XDC. Every port is a comment; remove the comment mark from the ports that you use |
| `tools/schematic_pins.py`, `tools/schematic-pins.csv` | Read the pins and nets of the FPGA from the schematic PDF |
| `tools/tables.py` | Makes `pins.csv`, `package-pins.csv` and `pynq_z2_master.xdc`, and prints where the sources differ |
| `package-pins.csv` | All 400 pins of the CLG400 package: bank, function, package delay, and the net of the schematic |
| `tools/package-dump.tcl`, `tools/package-dump.csv` | Write the package data of the XC7Z020 CLG400 from Vivado, and its output |
| `ps7/` | Exports the PS7 configuration of the board preset: `ps7_init_gpl.c` for U-Boot SPL, `ps7_init.tcl` for a JTAG boot, and the XSA |
| `jtag/load.sh`, `jtag/load.tcl` | Load a bitstream into the PL over the USB-JTAG. They do not touch the flash or a card |
| `jtag/boot.sh`, `jtag/boot.tcl` | Boot the PS over JTAG with `xsdb`: `ps7_init`, an optional bitstream, data files and an ELF program |
| `examples/pl-blinky/` | The smallest PL design: SYSCLK, the switches, the buttons and the LEDs |
| `linux/` | U-Boot, Linux 6.18 and Alpine Linux on F2FS: see [linux/README.md](linux/README.md) |
| `board-files/` | The Vivado board files, a copy of XilinxBoardStore: see [board-files/README.md](board-files/README.md) |
| `references/` | The schematic, the manual, the TUL XDC and PS7 preset, AMD documents and the Zynq Book: see [references/README.md](references/README.md) |

The scripts do not write into the repository unless you name it as their output. The start of each
script gives its usage.

## Quick start

```sh
export VIVADO=/path/to/Xilinx/2025.2.1/Vivado/bin/vivado
P=/path/to/this/repository

cd /some/writable/directory
sh $P/examples/pl-blinky/build.sh                       # into ./pynq-blinky
sh $P/jtag/load.sh pynq-blinky/build/blinky.bit         # loads the PL; no flash or card is touched
```

Vivado needs the Zynq-7000 devices. On 2026-11-23 the build ran with Vivado 2025.2.1: setup slack
+5.370 ns, hold slack +0.252 ns, 3 LUT and 30 FF. On 2026-11-24 the load ran on the board, and the
LEDs, the buttons and the switches did what `blinky.sv` describes.

## License

The files that the owner of this repository wrote are under the MIT License: see [LICENSE](LICENSE).
These files are third-party material and keep their own terms:

- `references/`: the documents of TUL, AMD, the authors of the Zynq Book and eneriz-daniel. See
  [references/README.md](references/README.md).
- `board-files/`: XilinxBoardStore, under the Apache License 2.0.
- `linux/patches/`: changes to Linux and U-Boot, under the GPL-2.0 of Linux and U-Boot.

`pins.csv` and `pynq_z2_master.xdc` state pin assignments of the schematic as facts.
