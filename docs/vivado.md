# Vivado

## Constraints

`pynq_z2_master.xdc` is the master XDC of this repository. Every port is a comment. Remove the
comment mark from the ports that the design uses, and rename them to the top-level ports.

`tools/tables.py` makes the file from three sources:

| Source | File | Use |
|---|---|---|
| Schematic R12 | `tools/schematic-pins.csv`, from `references/tul/TUL_PYNQ_Schematic_R12.pdf` | The pin, its function and its net. The reference |
| Package data | `tools/package-dump.csv`, from `tools/package-dump.tcl` (Vivado 2025.2.1, `xc7z020clg400-1`) | The check of the function and the bank of each pin, and `package-pins.csv` |
| TUL master XDC | `references/tul/pynq-z2_v1.0.xdc` | The port names and the I/O standards |
| Board file | `board-files/TUL/pynq-z2/A.0/part0_pins.xml` | A comparison only |

The master XDC sets `CFGBVS VCCO` and `CONFIG_VOLTAGE 3.3`, because bank 0 is at 3.3 V
**[schematic]** sheet 12. The PS pins (MIO and DDR) are not in the XDC. The PS7 configuration sets
them: see ps.md.

## Faults of the TUL XDC

The record follows the schematic. `tools/tables.py` corrects these faults of
`references/tul/pynq-z2_v1.0.xdc`:

- The XDC does not have V7. The schematic connects V7 (net `RP_IO04`) through R87 to `RPIO_27_R`,
  GPIO27 on pin 13 of the Raspberry Pi header **[schematic]** sheets 4 and 11. The port is
  `rpio_27_r`.
- The XDC has a port `a` on Y13 and a bus `a[0..5]`. One design cannot have both. Y13 is on the AREF
  position of the Arduino header J3 **[schematic]** sheet 4. The port is `ar_aref`.
- Ten comments of the XDC give a wrong function name: D18, E18, F19, G20, H20, J14, J16, U18, U19
  and W6. The package pins of these lines agree with the schematic. The package data of Vivado gives
  the function names of the schematic **[package]**.

The schematic has one fault of this kind. Sheet 11 gives K17 and K18 both the name
`IO_L12P_T1_MRCC_35`. The package data gives K18 `IO_L12N_T1_MRCC_35`, as the TUL XDC says
**[package]**. `tools/tables.py` corrects it.

`tools/tables.py` compares the function name and the bank of each pin of the schematic with the
package data of Vivado 2025.2.1 (`tools/package-dump.csv`). All 259 pins agree, after the K18
correction. Each of the 125 user I/O pins of the PL is on the schematic **[package]**.

## Board files

`board-files/` has the Vivado board files of XilinxBoardStore (see `board-files/README.md`). Tell
Vivado where they are before you create a project:

```tcl
set_param board.repoPaths [list /path/to/this/repository/board-files]
```

`board.xml` gives the vendor `tul.com.tw`, the name `pynq-z2`, the file version 1.0 and the part
`xc7z020clg400-1`. No design of this repository has used the board files yet.

The board file differs from the schematic on these pins:

| Pin | Schematic net | Board file | Note |
|---|---|---|---|
| P15 | `AR_SDA` | `i2c_scl_i` | The board file is right: P15 is SCL (measured, headers.md) |
| P16 | `AR_SCL` | `i2c_sda_i` | The board file is right: P16 is SDA (measured, headers.md) |
| F16 | `AR_SS` | `arduino_a0_a13_tri_i_10` | The branch `2022.2` of XilinxBoardStore has `spi_ss_i`, which agrees with the schematic |
| T16 | `AR_IO10` | `spi_ss_i` | The branch `2022.2` has `arduino_a0_a13_tri_i_10`, which agrees with the schematic |
| V7 | `RP_IO04` (GPIO27) | not present | |

The board file gives `LVCMOS33` to the HDMI output pairs. The TUL XDC gives `TMDS_33`. The board
file has no pin for H17 (`HDMI_RX_CEC`).

P15 and P16 are the I2C pins of the Arduino header. The schematic and the TUL XDC call P15 `AR_SDA`,
but P15 is SCL on the board (headers.md). The master XDC names P15 `ar_scl` and P16 `ar_sda`.

## PS7 preset

`references/tul/pynq-z2_v1.0_ps7_preset.tcl` is the PS7 preset of TUL for the `processing_system7`
IP. The board file has a preset too (`preset.xml`). ps.md describes the PS configuration.

## Every PL design has a PS7 cell

**A bitstream without a PS7 cell stops the PS if it is loaded while Linux runs** **[measured]**.
On 2026-11-24, Linux 6.18.64 ran from the card, with `LVL_SHFTR_EN` (0xF8000900) at 0xF:

| Bitstream, loaded with `jtag/load.sh` | Result |
|---|---|
| pl-blinky without a PS7 cell | SSH stopped answering 20 s to 30 s after the load, and the console too |
| pinprobe without a PS7 cell | The same (two times). Over JTAG, CPU0 was in the FIQ handler `__fiq_usr` of the kernel |
| No load; only `xsdb` and Vivado opened the JTAG target | No effect |
| pl-blinky with an empty PS7 cell (`PS7 ps7_i ();`) | No effect in 5 minutes |
| pinprobe with an empty PS7 cell | No effect; the pin reads were the same as without the cell |
| pl-blinky with a PS7 cell and `IRQF2P[16]` = 1 (the IRQ of CPU0 from the PL) | No effect in 60 s |
| pl-blinky with a PS7 cell and `IRQF2P[18]` = 1 (the FIQ of CPU0 from the PL) | The PS stopped at once. CPU0 was in `ct_kernel_enter_state`, on the path of the FIQ handler |

The cause is the FIQ of CPU0. `IRQF2P[19:16]` are the FIQ and IRQ lines of the two CPUs from the
PL. They are active high at the PS-PL interface (UG585, Table 7-2, page 216). Linux does not use
the FIQ: it handles it as an NMI and returns, and the FIQ, which is level-sensitive, is still on.
The empty PS7 cell and the `processing_system7` IP tie `IRQF2P` to 0. Thus, without a PS7 cell, the
FIQ line of CPU0 is active; this agrees with all the tests, but the level of the line was not
measured directly.

pl-blinky and pinprobe instantiate `PS7` with nothing connected. pl-interface connects
`M_AXI_GP0`, `S_AXI_HP0` and `IRQF2P[0]`, and ties the other `IRQF2P` inputs to 0
(pl-interface.md). A block design with `processing_system7` has the cell already. A design that
uses the FIQ of a CPU (`Core0_nFIQ`, `Core1_nFIQ` of the IP) must keep it inactive while Linux
runs. A bitstream that is loaded before Linux starts, or in JTAG mode, is not affected.

CPU0 read `ICCICR` = 0x1 while Linux ran. By UG585, Figure 7-3 (page 216), the FIQ from the PL then
goes through the GIC and not directly to the CPU, and with `FIQEn` = 0 the GIC does not signal a
FIQ. How the FIQ still reached CPU0 is not known (unknowns.md).
