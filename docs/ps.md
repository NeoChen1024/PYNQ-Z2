# PS: MIO, DDR3 and resets

The PS pins are not in the master XDC. The PS7 configuration of the block design sets them. Two
PS7 configurations for this board are in the repository:

| File | What it is |
|---|---|
| `board-files/TUL/pynq-z2/A.0/preset.xml` | The preset of the Vivado board file, the same as in XilinxBoardStore. Block automation of a design for the board `pynq-z2` applies it (vivado.md) |
| `references/tul/pynq-z2_v1.0_ps7_preset.tcl` | The PS7 preset of TUL. It is the configuration of the PYNQ image: I2C0 on MIO50/51, four PL clocks, `S_AXI_HP0`/`HP2`, `M_AXI_GP1` and PL interrupts. It does not set the MIO resets of the Ethernet and USB PHYs |

The DDR settings, the CPU clock and the MIO voltages of the two files agree. They differ in the
items in the table above, in MIO0/7/9 to 13/46/48/49 (GPIO and resets in `preset.xml`, unassigned in the Tcl),
and in the DDR part name (`MT41J256M16 RE-125` in `preset.xml`, `Custom` in the Tcl, with the same
timing values).

## MIO banks

| Bank | MIO | VCCO | Strap | Source |
|---|---|---|---|---|
| 500 | 0 to 15 | 3.3 V | `VCFG0` (MIO7) low | **[schematic]** sheets 10 and 12 |
| 501 | 16 to 53 | 1.8 V | `VCFG1` (MIO8) high | **[schematic]** sheets 10 and 12 |

`PS_MIO_VREF_501` (E11) is on `VREF0V9`: half of `VCC1V8` from R238/R241 (1 kΩ each). The board
preset sets `LVCMOS 3.3V` for bank 0 and `LVCMOS 1.8V` for bank 1 of the MIO.

## MIO table

The nets come from **[schematic]** sheet 10 (`tools/schematic-pins.csv`). The fourth column is the
function that `preset.xml` gives (`PCW_MIO_TREE_PERIPHERALS` and `PCW_MIO_TREE_SIGNALS`).

| MIO | Pin | Net | Board preset | Goes to |
|---|---|---|---|---|
| 0 | E6 | no net | GPIO: `gpio[0]` |  |
| 1 | A7 | `SPI_CS` | Quad SPI Flash: `qspi0_ss_b` | QSPI flash U16 |
| 2 | B8 | `SPI_DQ0/MODE3` | Quad SPI Flash: `qspi0_io[0]` | QSPI flash U16 |
| 3 | D6 | `SPI_DQ1/MODE1` | Quad SPI Flash: `qspi0_io[1]` | QSPI flash U16 |
| 4 | B7 | `SPI_DQ2/MODE2` | Quad SPI Flash: `qspi0_io[2]` | QSPI flash U16 |
| 5 | A6 | `SPI_DQ3/MODE0` | Quad SPI Flash: `qspi0_io[3]` | QSPI flash U16 |
| 6 | A5 | `SPI_SCK/MODE4` (R221, 0 Ω) | Quad SPI Flash: `qspi0_sclk` | QSPI flash U16 |
| 7 | D8 | `VCFG0` | GPIO: `gpio[7]` | Strap only |
| 8 | D5 | `SPI_SCLK_FB/VCFG1` | Quad SPI Flash: `qspi_fbclk` | QSPI feedback clock (no load) |
| 9 | B5 | `ETH_RST_B` | ENET Reset: `reset` | Ethernet PHY `PHYRSTB` |
| 10 | E9 | `ETH_INT_B` | GPIO: `gpio[10]` | Ethernet PHY `INTB` |
| 11 | C6 | `OTG_OC` | GPIO: `gpio[11]` | `OC#` of the VBUS switch U10 |
| 12 | D9 | `AR_RST` | GPIO: `gpio[12]` | Arduino reset, from SRST1 through Q9 |
| 13 | E8 | no net | GPIO: `gpio[13]` |  |
| 14 | C5 | `UART_TXD_IN` | UART 0: `rx` | U12 channel B TX |
| 15 | C8 | `UART_RXD_OUT` | UART 0: `tx` | U12 channel B RX |
| 16 | A19 | `ETH_TXCK` | Enet 0: `tx_clk` | Ethernet PHY U5 (RGMII) |
| 17 | E14 | `ETH_TXD0` | Enet 0: `txd[0]` | Ethernet PHY U5 (RGMII) |
| 18 | B18 | `ETH_TXD1` | Enet 0: `txd[1]` | Ethernet PHY U5 (RGMII) |
| 19 | D10 | `ETH_TXD2` | Enet 0: `txd[2]` | Ethernet PHY U5 (RGMII) |
| 20 | A17 | `ETH_TXD3` | Enet 0: `txd[3]` | Ethernet PHY U5 (RGMII) |
| 21 | F14 | `ETH_TXCTL` | Enet 0: `tx_ctl` | Ethernet PHY U5 (RGMII) |
| 22 | B17 | `ETH_RXCK` | Enet 0: `rx_clk` | Ethernet PHY U5 (RGMII) |
| 23 | D11 | `ETH_RXD0` | Enet 0: `rxd[0]` | Ethernet PHY U5 (RGMII) |
| 24 | A16 | `ETH_RXD1` | Enet 0: `rxd[1]` | Ethernet PHY U5 (RGMII) |
| 25 | F15 | `ETH_RXD2` | Enet 0: `rxd[2]` | Ethernet PHY U5 (RGMII) |
| 26 | A15 | `ETH_RXD3` | Enet 0: `rxd[3]` | Ethernet PHY U5 (RGMII) |
| 27 | D13 | `ETH_RXCTL` | Enet 0: `rx_ctl` | Ethernet PHY U5 (RGMII) |
| 28 | C16 | `OTG_DATA4` | USB 0: `data[4]` | USB PHY U9 (ULPI) |
| 29 | C13 | `OTG_DIR` | USB 0: `dir` | USB PHY U9 (ULPI) |
| 30 | C15 | `OTG_STP` | USB 0: `stp` | USB PHY U9 (ULPI) |
| 31 | E16 | `OTG_NXT` | USB 0: `nxt` | USB PHY U9 (ULPI) |
| 32 | A14 | `OTG_DATA0` | USB 0: `data[0]` | USB PHY U9 (ULPI) |
| 33 | D15 | `OTG_DATA1` | USB 0: `data[1]` | USB PHY U9 (ULPI) |
| 34 | A12 | `OTG_DATA2` | USB 0: `data[2]` | USB PHY U9 (ULPI) |
| 35 | F12 | `OTG_DATA3` | USB 0: `data[3]` | USB PHY U9 (ULPI) |
| 36 | A11 | `OTG_CLK` | USB 0: `clk` | USB PHY U9 (ULPI) |
| 37 | A10 | `OTG_DATA5` | USB 0: `data[5]` | USB PHY U9 (ULPI) |
| 38 | E13 | `OTG_DATA6` | USB 0: `data[6]` | USB PHY U9 (ULPI) |
| 39 | C18 | `OTG_DATA7` | USB 0: `data[7]` | USB PHY U9 (ULPI) |
| 40 | D14 | `SD_CCLK` (R217, 40.2 Ω) | SD 0: `clk` | SD card, through U6 |
| 41 | C17 | `SD_CMD` | SD 0: `cmd` | SD card, through U6 |
| 42 | E12 | `SD_D0` | SD 0: `data[0]` | SD card, through U6 |
| 43 | A9 | `SD_D1` | SD 0: `data[1]` | SD card, through U6 |
| 44 | F13 | `SD_D2` | SD 0: `data[2]` | SD card, through U6 |
| 45 | B15 | `SD_D3` | SD 0: `data[3]` | SD card, through U6 |
| 46 | D16 | `OTG_RESETN` | USB Reset: `reset` | USB PHY `RESETB` |
| 47 | B14 | `SD_CD` | SD 0: `cd` | Card-detect switch of SD1 |
| 48 | B12 | no net | GPIO: `gpio[48]` |  |
| 49 | C12 | no net | GPIO: `gpio[49]` |  |
| 50 | B13 | `HDMI_TX_SCL` | GPIO: `gpio[50]` | DDC of the HDMI output (hdmi.md) |
| 51 | B9 | `HDMI_TX_SDA` | GPIO: `gpio[51]` | DDC of the HDMI output (hdmi.md) |
| 52 | C10 | `ETH_MDC` | Enet 0: `mdc` | Ethernet PHY |
| 53 | C11 | `ETH_MDIO` | Enet 0: `mdio` | Ethernet PHY |

Notes on the table:

- MIO0, MIO13, MIO48 and MIO49 have no net. They are free GPIO of the PS, but no connector has them.
- MIO2 to MIO8 are also the boot straps (boot.md). A load on them must not change the strap
  values.
- MIO50 and MIO51 are the DDC (`SCL`, `SDA`) of the HDMI output. `preset.xml` sets them as GPIO.
  The TUL Tcl sets them as I2C0. Use I2C0 to read the EDID of a monitor (hdmi.md).
- MIO12 (`AR_RST`) has a 10 kΩ pull-up (R236). The open-drain buffer Q9 (`NC7WZ07P6X`) pulls it low
  while SRST1 is pressed. The Arduino reset of a shield follows it (headers.md).
- MIO11 (`OTG_OC`) is the over-current flag of the USB VBUS switch (usb.md). `preset.xml` sets it
  as GPIO.
- The board preset enables the internal pull-up of each MIO pin, except MIO2 to MIO8. It sets MIO9
  and MIO46 as the resets of the Ethernet PHY and the USB PHY, both active low.

## DDR3

**[schematic]** sheets 10 and 13:

- One DDR3 device, IC1, in a 96-ball FBGA. The schematic gives `MT41K512M16HA-125:A`; the fitted
  part is `MT41K256M16TW-107:P` (see below). The PS uses `DQ0` to
  `DQ15`, `DM0`/`DM1` and `DQS0`/`DQS1`. `DQ16` to `DQ31`, `DM2`/`DM3` and `DQS2`/`DQS3` have no
  net. The bus is 16 bits wide.
- Address `A0` to `A14` and `BA0` to `BA2` connect. `A15` (ball M7) of IC1 has no net. The PS has no
  `A15`.
- `CKE1`, `CS1#` and `ODT1` of IC1 have no net. `MEM_RESET#` has a 4.7 kΩ pull-down (R250).
- `CK`/`CK#` have 80.6 Ω between them (R218). There is no VTT termination.
- `ZQ` has 240 Ω (R248) to GND.
- `VDD`/`VDDQ` and `VCCO_DDR_502` are on `VCC1V5`. `DDR3_VREF` is half of `VCC1V5` from R237/R240
  (1 kΩ each). It goes to `VREFCA`/`VREFDQ` of IC1 and to `PS_DDR_VREF0`/`VREF1` (H6, P6).
- `PS_DDR_VRP` (H5) has 80.6 Ω (R219) to GND, and `PS_DDR_VRN` (G5) has 80.6 Ω (R220) to `VCC1V5`.

The documents do not agree on the part. The marking shows the fitted part:

| Source | Part | Size |
|---|---|---|
| **[schematic]** sheet 13 | `MT41K512M16HA-125:A` | Not given. In the naming of Micron the number reads as 512M x 16 |
| **[manual]** | "Micron 256Mx16 (MT41K512M16HA-125:A)" | 512 MB, 16 bits, up to 1050 Mb/s |
| `preset.xml` | `MT41J256M16 RE-125`: 4096 Mbit, 15 row bits, 10 column bits, 3 bank bits | 512 MiB (`PCW_DDR_RAM_HIGHADDR` 0x1FFFFFFF) |
| The marking of IC1, seen by the owner on 2026-11-24 | `3MP17`, `D9SHD`. The Micron FBGA decoder gives `MT41K256M16TW-107:P` for `D9SHD` | 4 Gbit, 256M x 16: 512 MiB |

The fitted part is `MT41K256M16TW-107:P`. The record follows the marking. The schematic is wrong,
and the manual gives the correct organization with the part number of the schematic.

The data sheet of the part is `references/micron/MT41K_DDR3L_4Gb_Rev.Q_Dec2017_DS.pdf` (pages 1
and 2):

- It is a DDR3L device: VDD and VDDQ are 1.35 V. It also operates at 1.5 V ±0.075 V, as DDR3. The
  board supplies 1.5 V (`VCC1V5`), so the part runs in its 1.5 V mode. For that mode the data sheet
  refers to the DDR3 (1.5 V) data sheet of die revision E, which is not in `references/`.
- `256M16` is 32 Meg x 16 x 8 banks: 15 row address bits (`A0` to `A14`), 10 column address bits,
  3 bank address bits, 2 KB page. This is the geometry that `preset.xml` sets.
- `TW` is the 96-ball FBGA of 8 mm x 14 mm. `-107` is DDR3-1866 (tCK 1.07 ns, CL 13). It is also
  correct for DDR3-1600 with CL 11.
- No temperature mark means the commercial range, 0 °C to 95 °C case temperature. `:P` is the
  revision.

The part uses `A0` to `A14` only, and the PS has no `A15`. U-Boot found 512 MiB, and the memory test passed (see
below). The board preset runs the part far below its rating: 1050 Mb/s.

The board preset runs the DDR at 525 MHz (1050 Mb/s), CL 7, CWL 6, with write leveling, read gate
and data eye training. Its four `PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY` values are negative (-0.051,
-0.006, -0.009 and -0.033 ns). Vivado 2025.2.1 gives a critical warning for each of them when
`ps7/build.sh` applies the preset (2026-11-23): it says that negative DQS skew values can make the
DDR fail. It has the board delays for each byte lane (`PCW_UIPARAM_DDR_BOARD_DELAY0`
to `3`, `PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0` to `3`). The manual says that TUL calculated them from
the PCB trace lengths. The data sheet DS187 gives 1066 Mb/s as the DDR3 limit of the XC7Z020.

### DDR test

On 2026-11-24, the DDR passed one memory test with the board preset **[measured]**:

- `jtag/boot.sh` ran `ps7_init.tcl` of `ps7/build.sh` and started U-Boot 2026.10 (`linux/build-uboot.sh`).
- U-Boot ran `mtest 0x00100000 0x1d000000 0 1`: 463 MiB, one iteration, 12 minutes. It found 0 errors.
- The test is the alternative test of U-Boot with the bit-flip test (`CONFIG_SYS_ALT_MEMTEST`,
  `CONFIG_SYS_ALT_MEMTEST_BITFLIP`). The data cache was on.
- The range stops below the relocated U-Boot. The first 1 MiB was not tested.

This is one pass on one board, at a temperature that was not measured.

### Data eye

On 2026-11-24, `tools/ddrscan/ddr_eye.tcl` measured the data eye of each byte lane **[measured]**
(`tools/ddrscan/eye-2026-11-24.csv`). U-Boot waited at its prompt with the DDR set up by the SPL and
the board preset. The script stopped both CPUs and, over JTAG, forced the slave delay of one lane
in the PHY (`wr_data_slvN` or `phy_rd_dqs_cfgN`, bit 10). For each delay it wrote 8 KB to the DDR,
read it back and counted the wrong bits of each lane. The write delays moved in steps of 4 taps,
the read delays in steps of 2.

| Eye | Lane | Delay without errors (taps) | Width | Delay that training set | Margin below / above |
|---|---|---|---|---|---|
| Write data | 0 | 72 to 120 | 48 | 99 | 27 / 21 |
| Write data | 1 | 72 to 120 | 48 | 95 | 23 / 25 |
| Read DQS | 0 | 6 to 56 | 50 | 32 | 26 / 24 |
| Read DQS | 1 | 2 to 54 | 52 | 30 | 28 / 24 |

- A tap is about 14 ps to 15 ps. This follows from the ratios and the taps that the PHY applied
  (for example a write data ratio of 186/256 of a cycle gave 99 taps); it is not a separate
  measurement.
- Thus each eye is about 700 ps wide, about 0.7 of the bit time of 952 ps at 1050 Mb/s. The
  settings of training are near the middle, with about 0.3 bit time (300 ps to 400 ps) on each side.
- The negative DQS-to-CLK delays of the board preset (above) do not show in these results: write
  leveling and training set the delays, and they have margin on both sides.
- Limits: one board, one temperature (not measured), 8 KB for each point. The DDR accesses over
  JTAG are slower than accesses of the CPUs, so they cause less simultaneous switching noise.
- A new ratio in `wr_data_slvN` took effect only at the next DDR initialization; a forced delay took
  effect at once. `ddr_eye.tcl` thus uses the force bits.

## PS resets

**[schematic]** sheets 10 and 14:

| Signal | Pin | Source |
|---|---|---|
| `PS_POR_B` | C7 | `PG_ALL`, the power good of U18 (power.md) |
| `PS_SRST_B` | B10 | `PS_RST`: the button SRST1 to GND, through R239 (200 Ω). R235 (10 kΩ) pulls it up to `VCC1V8` |

The manual says that a system reset (SRST1) clears the PS memories, the OCM and the PL, but does
not read the boot straps again. The PROG1 button resets only the PL (boot.md).

## Clocks of the board preset

| Clock | Frequency | Parameter |
|---|---|---|
| CPU | 650 MHz | `PCW_APU_PERIPHERAL_FREQMHZ`, ratio 6:2:1 |
| DDR | 525 MHz | `PCW_UIPARAM_DDR_FREQ_MHZ` |
| `FCLK_CLK0` (PL) | 100 MHz | `PCW_FPGA0_PERIPHERAL_FREQMHZ`; `FCLK_CLK1` to `3` are off. Linux keeps `FCLK_CLK0` on (pl-interface.md) |
| QSPI | 200 MHz (controller reference) | `PCW_QSPI_PERIPHERAL_FREQMHZ` |
| SDIO | 50 MHz | `PCW_SDIO_PERIPHERAL_FREQMHZ` |
| UART | 100 MHz reference, 115200 baud | `PCW_UART_PERIPHERAL_FREQMHZ` |
| Ethernet 0 | 1000 Mb/s (125 MHz) | `PCW_ENET0_PERIPHERAL_FREQMHZ` |

The input of all of them is the 50 MHz `PS_CLK` (clocks.md).

On 2026-11-24, U-Boot `clk dump` after `ps7_init` showed the same values **[measured]**: ARM PLL
1300 MHz, CPU 650 MHz, DDR 525 MHz, `FCLK0` 100 MHz, LQSPI 200 MHz, SDIO0 50 MHz, UART0 100 MHz and
GEM0 125 MHz. U-Boot calculates them from the clock registers of the PS. No instrument measured
them. `bdinfo` showed 512 MiB of DRAM.
