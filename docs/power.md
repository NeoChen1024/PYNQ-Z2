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

The manual names the power LED, the `DONE` LED and the status LEDs of USB and Ethernet.

The conditions that pull `PG_ALL` low come from the TPS65400 data sheet (page 8) and sheet 15:

- If `VCC5V0` falls below the input UVLO (3.4 V to 3.75 V), all four outputs stop.
- If an output stays below 83 % of its set voltage for 55 µs to 95 µs, `PGOOD` falls. It
  rises again above 92 %.
- An overvoltage (111 %) or the thermal shutdown (160 °C) also pulls `PGOOD` low.
- R290 (20 kΩ) and R291 (10 kΩ) give `EN_1` = `VCC5V0` / 3. The enable falls at 0.97 V to
  1.07 V, which is 2.9 V to 3.2 V of `VCC5V0`. Thus the UVLO stops the outputs first.

These figures are derived, not measured.

## Reset reason

The boot ROM writes the reason of the last reset into `REBOOT_STATUS` (0xF8000258). Only a
power-on reset clears it (UG585, page 1606). Bit 22 is POR, bit 21 `SRST_B`, bit 19 the SLCR
soft reset (Linux `reboot`), and bits 18 to 16 are the watchdogs. Linux reads it with
`/dev/mem`. Linux changes only bits 31 to 24 (`arch/arm/mach-zynq/slcr.c`).

After a power-on with the switch, the register read 0x00400000 (2026-11-25) **[measured]**.

On 2026-11-25 the board reset itself while Linux was idle. After this reset, the register read
0x00400000: a power-on reset, thus `PG_ALL` fell. The FT2232H, which runs from `VCC3V3`, did not
disconnect from the host. Thus `VCC3V3` stayed high enough for the FT2232H. The kernel and the
host logs showed nothing at that time. The cause is not known (unknowns.md).

A later run of 8 hours, idle on USB power with an inline meter, had no reset (2026-11-25)
**[measured]**. A script read the XADC every 0.5 s and printed the minimum and the maximum each
minute: 474 minutes. The lowest values were 1.006 V (`VCCINT`), 1.772 V (`VCCAUX`) and 1.471 V
(`VCCO_DDR`).

## Consumption

The owner read an inline USB meter on J8, with J9 on `USB` (2026-11-25) **[measured]**. The PL was
not configured, Ethernet had a 1 Gb/s link, and no USB device was connected. Linux ran
`linux/README.md`, with the CPU at 650 MHz or 325 MHz (`ondemand`).

| Load | Current at J8 | Voltage at J8 |
|---|---|---|
| Linux idle | about 0.30 A | 4.8 V to 4.9 V |
| Two shell busy loops, 60 s | 0.41 A | at least 4.88 V |
| Two `memtester 100M`, 60 s | 0.48 A | at least 4.88 V |

From the start of the first load to the end of the second, the XADC read 398 samples, one every
0.2 s, from `xadc_hwmon` (fpga.md). Each SoC rail stayed within 1.5 % of the set voltage of its
regulator (1.02 V, 1.80 V, 1.50 V). The die temperature was at most 49.2 °C. The full load is near the 0.5 A of a USB 2.0 port. A PL design or a USB device adds
current. Then use the barrel jack DC1, as the manual recommends.

## Sequence of U18

The order of the four outputs is not set by a pin. The TPS65400 keeps it in its EEPROM, which only
I2C can change (data sheet `references/ti/tps65400_SLVSCQ9E.pdf`, section 8.3.1, pages 13 to 15).
On the board **[schematic]** sheets 14 and 15:

- `ENSW1/ENSEQ`, `EN2`, `EN3` and `EN4` are all on one net, `EN_1`. R290 and R291 divide `VCC5V0`
  to it, and Q17 pulls it low while the power switch is off.
- `CE` goes only to JP2, which is not fitted. The pin has an internal pull-up (page 4).
- Each soft-start pin has 33 nF (C173, C180, C187, C193). R271 (150 kohm) on `RCLOCK_SYNC` sets
  about 1.2 MHz (Equation 3, page 18).
- The feedback dividers give 1.02 V, 3.30 V, 1.80 V and 1.50 V with the default reference of
  0.8 V (Equation 4, pages 23 and 24).

With the factory defaults (SEQUENCE_ORDER 0 for all outputs, page 15), all four outputs start
together, with the same soft-start time of about 5 ms (Equation 2, pages 17 and 18). This is
derived, not measured. It is not the order that DS187 recommends (VCCINT first, page 8), but
DS187 gives that order for the current and the I/O state, not as a limit. Whether TUL changed the
EEPROM of U18 is not known; a measurement of the four rails at power-on would show the order
(unknowns.md).
