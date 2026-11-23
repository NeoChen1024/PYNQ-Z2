# FPGA (XC7Z020)

The board has one Zynq-7000 SoC, U15. The schematic marks it `XC7Z020-1CLG400C` **[schematic]**
sheets 9 to 12. The Vivado part is `xc7z020clg400-1`.

| Item | Value | Source |
|---|---|---|
| Package | CLG400 | **[schematic]** |
| Speed grade | -1, commercial temperature (the `C`) | **[schematic]** marking |
| PS | Two ARM Cortex-A9 cores | **[manual]** |
| CPU clock of the board preset | 650 MHz | Board file `preset.xml` (`PCW_APU_PERIPHERAL_FREQMHZ`) |
| CPU clock limit of a -1 part | 667 MHz (6:2:1 clock ratio) | Data sheet DS187, `FCPU_6X4X_621_MAX` |
| PL | 13,300 slices, 220 DSP slices, 630 KB block RAM | **[manual]** |

The designs here are built as -1. No measurement on this board shows a faster grade.

## Banks

| Bank | Kind | VCCO | User pins with a net | Source |
|---|---|---|---|---|
| 0 | Configuration | 3.3 V (`CFGBVS_0` on 3.3 V) | | **[schematic]** sheets 9 and 12 |
| 13 | PL, HR | 3.3 V | 24 of 25 (V5 has no net) | **[schematic]** sheets 11 and 12 |
| 34 | PL, HR | 3.3 V | 50 of 50 | **[schematic]** sheets 11 and 12 |
| 35 | PL, HR | 3.3 V | 50 of 50 | **[schematic]** sheets 11 and 12 |
| 500 | PS MIO 0 to 15 | 3.3 V | 14 of 16 MIO | **[schematic]** sheets 10 and 12 |
| 501 | PS MIO 16 to 53 | 1.8 V | 36 of 38 MIO | **[schematic]** sheets 10 and 12 |
| 502 | PS DDR | 1.5 V | 16-bit DDR3 | **[schematic]** sheets 10, 12 and 13 |

Bank 13 of the CLG400 package has 25 user pins only. All PL banks are at 3.3 V. Thus a PL design
uses `LVCMOS33` or `TMDS_33`, and there is no 1.8 V or LVDS output in the PL. `pins.csv` has each
pin. The master XDC `pynq_z2_master.xdc` sets `CFGBVS VCCO` and `CONFIG_VOLTAGE 3.3`.

The MIO pins and the DDR pins are not in the XDC. The PS7 configuration sets them (ps.md).

## Configuration pins (bank 0)

**[schematic]** sheet 9:

- `PROGRAM_B` (L6) has a 4.7 kΩ pull-up (R213) and the push button PROG1 to GND.
- `INIT_B` (R10) has a 4.7 kΩ pull-up (R216).
- `DONE` (R11) drives the LED CR7 through R211 (220 Ω). The LED is on while `DONE` is high.
- `TCK`, `TMS`, `TDI`, `TDO` go to the USB-JTAG bridge and to the header JP3 (jtag-uart.md).

## XADC

**[schematic]** sheets 4, 9 and 15:

- `VP_0`/`VN_0` (K9/L10) connect through 140 Ω (R214, R215) to `XADC_V_P`/`XADC_V_N` on
  pins 1 and 2 of the 4-pin header J5. Pin 3 is `XADCGND`, and pin 4 is `XADCVREF`.
- `VREFP_0` takes `XADCVREF` from U21, marked `REF3012AIDBZT`. `VREFN_0` is on `XADCGND`.
- `VCCADC_0` takes `XADC1V8`: `VCC1V8` through the ferrite B10.
- The six analog inputs of the Arduino header go to auxiliary channels of bank 35:

| Net | Pins (P/N) | Channel |
|---|---|---|
| `AR_AN0` | E17/D18 | VAUX1 |
| `AR_AN1` | E18/E19 | VAUX9 |
| `AR_AN2` | K14/J14 | VAUX6 |
| `AR_AN3` | K16/J16 | VAUX15 |
| `AR_AN4` | J20/H20 | VAUX5 |
| `AR_AN5` | G19/G20 | VAUX13 |

The channel numbers come from the pin function names (`_ADnP`/`_ADnN`) on sheet 11. headers.md
gives the analog front end of these inputs.

## The schematic file

The file is `references/tul/TUL_PYNQ_Schematic_R12.pdf`. Its PDF title is `tul_pynq_r11_0109`, and
the title block of each sheet gives Rev `R10`, dated 2018-01-09. Which revision the fitted board
follows is not known (unknowns.md).
