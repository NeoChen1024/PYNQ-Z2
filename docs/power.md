# Power

## Inputs

The board takes power from one of two sources **[manual]**:

- The micro-USB connector J8 (`VBUS`). It also carries the USB-JTAG and the UART (jtag-uart.md).
- The barrel jack DC1, 7 V to 15 V DC, center positive. The manual recommends 12 V. A battery on
  the `VIN` pin of the Arduino connector J7 is the same input.

The jumper J9 selects the source **[schematic]** sheet 15 ("MAIN Power Select"):

| J9 position | Source of `VCC5V0` |
|---|---|
| 1-2 (`REG`) | `REG5V0`, from the jack DC1 through the buck regulator U19 |
| 2-3 (`USB`) | `VUSB`, from `VBUS` of J8 through the P-MOSFET Q16 |

The manual describes the same two positions.

## Power switch

The slide switch `PSON_SW` turns the board on and off **[schematic]** sheet 15:

- In the on position, the switch pulls `PS_ON` low. Then Q13 drives `EN_MAIN` high, and Q17 releases
  `EN_1`.
- `EN_1` is the enable of all four outputs of U18 (sheet 14). `R290`/`R291` make it from `VCC5V0`.
- `EN_MAIN` switches on Q16 (`VBUS` to `VUSB`), Q14 (`VU` to `VU_CK`) and the jack regulator U19
  through Q12/Q11. It also releases the reset of the USB bridge U12 (jtag-uart.md).
- `VU` (the jack) and `VBUS` (USB) both feed the switch circuit through the dual diode D12
  (`BAT54CW-L`).

Thus the USB-JTAG bridge has no power while the switch is off.

## Regulators

| Part | Marking | Input | Output | Note on the sheet | Source |
|---|---|---|---|---|---|
| U19 | `TLV62130RGT` | `VU` (jack) | `REG5V0` | Enable `EN_6213` from `EN_MAIN` | **[schematic]** sheet 15 |
| U18, SW1 | `TPS65400RGZ` | `VCC5V0` | `VCC1V0` | "1.0V 2.6A" | **[schematic]** sheet 14 |
| U18, SW2 | | | `VCC3V3` | "3.3V 1.6A" | **[schematic]** sheet 14 |
| U18, SW3 | | | `VCC1V8` | "1.8V 1.8A" | **[schematic]** sheet 14 |
| U18, SW4 | | | `VCC1V5` | "1.5V 1.8A" | **[schematic]** sheet 14 |
| U20 | `LP5907MFX-3.3/NOPB` | `VCC5V0` | `AVCC3V3` (audio codec) | | **[schematic]** sheet 15 |
| U21 | `REF3012AIDBZT` | `XADC1V8` | `XADCVREF` | | **[schematic]** sheet 15 |

The currents are the notes on sheet 14. They are not measured. U18 has an I2C port. Its pins go
to the 5-pin header JP2, which the schematic marks `/X`. JP2 is on the back of the board, and the
owner saw it not fitted (2026-11-24). No FPGA pin connects to that I2C port.

## Rails of the SoC

**[schematic]** sheet 12:

| Rail | Supplies |
|---|---|
| `VCC1V0` | `VCCINT`, `VCCPINT`, `VCCBRAM` |
| `VCC1V8` | `VCCAUX`, `VCCPAUX`, `VCCPLL` (through the ferrite B9), `VCCO_MIO1_501`, `VCCBATT_0` |
| `VCC1V5` | `VCCO_DDR_502` and the DDR3 (ps.md) |
| `VCC3V3` | `VCCO_0`, `VCCO_13`, `VCCO_34`, `VCCO_35`, `VCCO_MIO0_500` |

`VCCBATT_0` is on `VCC1V8`. There is no battery for the BBRAM key of the SoC.

## Power good and power-on reset

**[schematic]** sheets 10 and 14:

- The `PGOOD` output of U18 is `PG_ALL`. R274 (10 kΩ) pulls it up to `VCC3V3`, and C198 (1 µF)
  is on it.
- `PG_ALL` goes to `PS_POR_B` (C7). The PS stays in its power-on reset until all four outputs of
  U18 are good. The manual states the same.
- `PG_ALL` also switches the power LED CR8 through Q10.

The manual names the power LED, the `DONE` LED and the status LEDs of USB and Ethernet. The
sequence of the four outputs of U18 is not known (unknowns.md).
