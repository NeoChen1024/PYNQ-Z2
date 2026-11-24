# Headers: Pmod, Raspberry Pi, Arduino

The board has two Pmod ports, a 40-pin Raspberry Pi header and Arduino shield headers. All their
I/O pins go to the PL at 3.3 V (banks 13, 34 and 35), except `AR_RST`, which is on MIO12
**[schematic] sheets 3, 4, 10, 11, 12**. The ports are those of `pynq_z2_master.xdc`. Use
`LVCMOS33`.

**No header pin is 5 V tolerant.** The manual gives these limits for the Arduino digital pins
**[manual]**:

| State of the board | Absolute minimum | Recommended minimum | Recommended maximum | Absolute maximum |
|---|---|---|---|---|
| Powered | -0.4 V | -0.2 V | 3.4 V | 3.75 V |
| Not powered | -0.4 V | | | 0.55 V |

The manual warns that a shield with 5 V outputs can damage the Zynq. The same pins of the FPGA
are on the Pmod and Raspberry Pi headers, so the limits apply there too.

The pinout diagram `references/pinout/pinout.svg` (third party, see `references/README.md`)
shows all headers on one page.

## Pmod ports

Both ports are 2x6 right-angle female connectors (`PH(F)_6x2H_R2.54mm`) **[schematic] sheet 3**.
Pins 5 and 11 are ground; pins 6 and 12 are `VCC3V3`. The manual gives 1 A for the supply pins
**[manual]**.

Each I/O line has a 200 ohm series resistor between the FPGA and the connector (R1 to R8 for
PmodA, R18 to R29 for PmodB). On the connector side, ESD arrays (`AZ1045-04F`, U1 to U4) protect
the lines **[schematic] sheet 3**.

| Pmod pin | PmodA net | Pin | Port | Also on RPi pin | PmodB net | Pin | Port |
|---|---|---|---|---|---|---|---|
| 1 | `JA1_P` | Y18 | `ja[0]` | 7 | `JB1_P` | W14 | `jb[0]` |
| 2 | `JA1_N` | Y19 | `ja[1]` | 29 | `JB1_N` | Y14 | `jb[1]` |
| 3 | `JA2_P` | Y16 | `ja[2]` | 27 (pull-up) | `JB2_P` | T11 | `jb[2]` |
| 4 | `JA2_N` | Y17 | `ja[3]` | 28 (pull-up) | `JB2_N` | T10 | `jb[3]` |
| 7 | `JA3_P` | U18 | `ja[4]` | 31 | `JB3_P` | V16 | `jb[4]` |
| 8 | `JA3_N` | U19 | `ja[5]` | 26 | `JB3_N` | W16 | `jb[5]` |
| 9 | `JA4_P` | W18 | `ja[6]` | 3 (pull-up) | `JB4_P` | V12 | `jb[6]` |
| 10 | `JA4_N` | W19 | `ja[7]` | 5 (pull-up) | `JB4_N` | W13 | `jb[7]` |

All 16 pins are in bank 34. Each `_P`/`_N` couple is a differential pair of the FPGA (for example
Y18 is `IO_L17P_T2_34` and Y19 is `IO_L17N_T2_34`) **[schematic] sheet 11**. The series resistors
limit the speed of the lines; no measurement was made.

The board file names the pins `JA1` to `JA10` and `JB1` to `JB10` by the connector pin. The TUL XDC
and the board file agree with the table.

### PmodA and the Raspberry Pi header share eight pins

**[schematic] sheets 3, 4**:

- Each of the eight `JA*` nets leaves the FPGA pin and branches: one branch goes through the 200 ohm
  of sheet 3 to the Pmod pin, the other through a second 200 ohm (R688 to R695) to the Raspberry Pi
  header.
- R305 to R308 (2.2 kohm) pull up `RPIO_02_R`, `RPIO_03_R`, `RPIO_SD_R` and `RPIO_SC_R` to `VCC3V3`.
  These are the I2C pins of a Raspberry Pi. Thus **PmodA pins 3, 4, 9 and 10 have a pull-up**: 2.4
  kohm from the FPGA pin, 2.6 kohm from the Pmod pin.
- A design must not use PmodA and the Raspberry Pi header for different purposes at the same time.
  A device on one header sees the signals of the other.

Sheet 4 has a reference table of the eight shared pins. The revision history (sheet 2) says that
`JA4_P` and `JA4_N` were connected to RPi pins 3 and 5 in revision B.

## Raspberry Pi header

The header `RPI_IDE` is a 2x20 box header (`BOX_HD_2X20P`) **[schematic] sheet 4**. Its supply pins
are `VCC3V3` (1, 17) and `VCC5V0` (2, 4). The ground pins are 6, 9, 14, 20, 25, 30, 34 and 39.

The 28 I/O nets are called `RPIO_<n>_R`. `<n>` is the GPIO number that a Raspberry Pi has on the same
header pin. Twenty of the nets come from `RP_IO02` to `RP_IO21` through 200 ohm (R82 to R247); the
other eight are the PmodA nets above.

| RPi pin | Net | Pin | Bank | Port | Note |
|---|---|---|---|---|---|
| 3 | `RPIO_02_R` | W18 | 34 | `rpio_02_r` | PmodA 9; 2.2 kohm pull-up |
| 5 | `RPIO_03_R` | W19 | 34 | `rpio_03_r` | PmodA 10; 2.2 kohm pull-up |
| 7 | `RPIO_04_R` | Y18 | 34 | `rpio_04_r` | PmodA 1 |
| 8 | `RPIO_14_R` | V6 | 13 | `rpio_14_r` | |
| 10 | `RPIO_15_R` | Y6 | 13 | `rpio_15_r` | |
| 11 | `RPIO_17_R` | U7 | 13 | `rpio_17_r` | |
| 12 | `RPIO_18_R` | C20 | 35 | `rpio_18_r` | |
| 13 | `RPIO_27_R` | V7 | 13 | `rpio_27_r` | Not in the TUL XDC or the board file |
| 15 | `RPIO_22_R` | U8 | 13 | `rpio_22_r` | |
| 16 | `RPIO_23_R` | W6 | 13 | `rpio_23_r` | |
| 18 | `RPIO_24_R` | Y7 | 13 | `rpio_24_r` | |
| 19 | `RPIO_10_R` | V8 | 13 | `rpio_10_r` | |
| 21 | `RPIO_09_R` | V10 | 13 | `rpio_09_r` | |
| 22 | `RPIO_25_R` | F20 | 35 | `rpio_25_r` | |
| 23 | `RPIO_11_R` | W10 | 13 | `rpio_11_r` | |
| 24 | `RPIO_08_R` | F19 | 35 | `rpio_08_r` | |
| 26 | `RPIO_07_R` | U19 | 34 | `rpio_07_r` | PmodA 8 |
| 27 | `RPIO_SD_R` | Y16 | 34 | `rpio_sd_r` | PmodA 3; 2.2 kohm pull-up |
| 28 | `RPIO_SC_R` | Y17 | 34 | `rpio_sc_r` | PmodA 4; 2.2 kohm pull-up |
| 29 | `RPIO_05_R` | Y19 | 34 | `rpio_05_r` | PmodA 2 |
| 31 | `RPIO_06_R` | U18 | 34 | `rpio_06_r` | PmodA 7 |
| 32 | `RPIO_12_R` | B20 | 35 | `rpio_12_r` | |
| 33 | `RPIO_13_R` | W8 | 13 | `rpio_13_r` | |
| 35 | `RPIO_19_R` | Y8 | 13 | `rpio_19_r` | |
| 36 | `RPIO_16_R` | B19 | 35 | `rpio_16_r` | |
| 37 | `RPIO_26_R` | W9 | 13 | `rpio_26_r` | |
| 38 | `RPIO_20_R` | A20 | 35 | `rpio_20_r` | |
| 40 | `RPIO_21_R` | Y9 | 13 | `rpio_21_r` | |

**V7 (pin 13, GPIO27) is missing from the TUL XDC and from the board file.** Sheet 4 shows it:
`RP_IO04` goes through R87 to `RPIO_27_R`. The master XDC of this repository adds it as `rpio_27_r`.
The manual has it **[manual]**.

The board file calls the pins `raspberry_pi_tri_i_0` to `raspberry_pi_tri_i_24` (GPIO2 to GPIO26)
and `respberry_sd_i`, `respberry_sc_i`. Its pins agree with the table.

## Arduino headers

The manual calls the headers "Arduino Shield compatible" **[manual]**. **[schematic] sheet 4**:

| Header | Part | Pins |
|---|---|---|
| J4 | 1x8 female | `AR0` to `AR7` on pins 1 to 8 |
| J3 | 1x10 female | `AR8` to `AR13` on pins 1 to 6; ground (7); `A` (8); SDA (9, net `AR_SCL`); SCL (10, net `AR_SDA`) |
| J1 | 1x6 female | `A5` (1) to `A0` (6) |
| J7 | 1x8 female | Power and reset, see below |
| SPI_CNN1 | 2x3 header | `MISO` (1), `VCC3V3` (2), `SCK` (3), `MOSI` (4), `SS` (5), ground (6) |

### Digital pins

`AR_IO0` to `AR_IO13` and `AR_IOA` go through 200 ohm (R76 to R93, R51 to R61, R67) to the header.
The manual names this resistor a protection against short circuits **[manual]**.

| Header pin | Net | Pin | Port |
|---|---|---|---|
| AR0 to AR7 (J4.1 to J4.8) | `AR_IO0` to `AR_IO7` | T14, U12, U13, V13, V15, T15, R16, U17 | `ar[0]` to `ar[7]` |
| AR8 to AR13 (J3.1 to J3.6) | `AR_IO8` to `AR_IO13` | V17, V18, T16, R17, P18, N17 | `ar[8]` to `ar[13]` |
| A (J3.8) | `AR_IOA` | Y13 | `ar_aref` |

All are in bank 34, except Y13 in bank 13. J3.8 is the AREF position of an Arduino Uno R3. On this
board it is a digital I/O pin. The TUL XDC calls its port `a`, which cannot exist in one design with
the bus `a[0..5]`. The master XDC calls it `ar_aref`.

U13 (`AR_IO2`) is also the PUDC_B pin of the FPGA (`IO_L3P_T0_DQS_PUDC_B_34`). The schematic shows
no resistor on it other than the 200 ohm to the header. U13 has no external pull **[measured]**: it
followed the internal pull of the PL in both pinprobe builds (2026-11-24). Thus PUDC_B floats during
configuration if nothing is on AR2. See [unknowns.md](unknowns.md).

The state of the pins before configuration **[measured]**, on 2026-11-24: `tools/bscan/sample.tcl`
sent JPROGRAM, which cleared the PL, and then sampled the boundary register four times:

- 60 of the 68 pins that follow the internal pull (fpga.md, "Pin census") read 1, also V5, which
  has no connection. Thus the I/O pins have weak pull-ups before configuration.
- LD0 to LD3 and BTN0 to BTN3 read 0. Each has a weak path to ground (the LED, the 20 kohm of the
  button), which the pull-up cannot overcome. The owner saw the LEDs glow weakly while the PL was
  configured: the current of the pull-up goes through the LED, and the LED holds the pin below the
  input high level.
- The pins with an external pull-up read 1, and those with a pull-down read 0.
- U13 (PUDC_B) read 1. PUDC_B high disables the pull-ups, so this reading does not agree with the
  pull-ups above.

UG470 (`references/amd/ug470_7Series_Config_v1.17.pdf`, page 22) explains the disagreement. PUDC_B
low enables the internal pull-ups of the SelectIO pins after power-up and during configuration;
high disables them. PUDC_B must connect directly, or through 1 kohm or less, to VCCO or GND: "Do not
allow this pin to float before and during configuration." **On this board PUDC_B floats**: it has
only the 200 ohm to AR2 of the Arduino header. Thus whether the pins have pull-ups before and during
configuration is not defined by the board. On 2026-11-24 they had pull-ups.

- A shield that drives AR2 decides the state: low enables the pull-ups, high disables them.
- For a defined state, connect AR2 to GND (pull-ups) or to 3.3 V (no pull-ups) through 1 kohm or
  less.
- A design that needs a pin low before configuration needs an external pull-down in any case. A sample with
pinprobe loaded gave the same 124 values as its census, which checks the cell map of the BSDL.

T16 is `AR_IO10`; F16 is `AR_SS`. The board file of XilinxBoardStore 2025.2 and master gives the
two pins the other way round; its 2022.2 branch agrees with the schematic (`pins.csv`).

### I2C

The nets `AR_SCL` (P16) and `AR_SDA` (P15) go to J3 without series resistors. R49 and R50 (2.2 kohm)
pull them up to `VCC3V3` **[schematic] sheet 4**.

**P16 is SDA and P15 is SCL** **[measured]**. On 2026-11-24, `tools/pinprobe/` watched all PL pins
while the owner touched the J3 pin with the silkscreen SDA with a wire from GND, then the pin with
the silkscreen SCL, two times. P16 went low for SDA, and P15 went low for SCL. The net names of the
schematic are wrong. The master XDC follows the measurement: port `ar_sda` on P16 and `ar_scl` on
P15.

The sources:

- The schematic and the TUL XDC: P15 is `AR_SDA` on J3.10; P16 is `AR_SCL` on J3.9.
- The manual: J3.9 is `AR_SDA` on P16; J3.10 is `AR_SCL` on P15 **[manual]**.
- The board file: P15 is `i2c_scl_i`; P16 is `i2c_sda_i`.

All sources put P16 on J3.9 and P15 on J3.10. On an Arduino Uno R3, the pin next to AREF (J3.9) is
SDA and the last pin (J3.10) is SCL. Thus a shield finds its SDA on P16, as the manual and the board
file say. The measurement agrees with this.

### SPI

The 2x3 header SPI_CNN1 has the ICSP layout of an Arduino, but pin 5 is `SS` and not a reset
**[schematic] sheet 4**. Each line has 200 ohm (R106 to R109).

| SPI_CNN1 pin | Net | Pin | Port |
|---|---|---|---|
| 1 | `AR_MISO` | W15 | `ck_miso` |
| 3 | `AR_SCK` | H15 | `ck_sck` |
| 4 | `AR_MOSI` | T12 | `ck_mosi` |
| 5 | `AR_SS` | F16 | `ck_ss` |

The SPI lines do not go to J3: D10 to D13 of the shield are `AR_IO10` to `AR_IO13`. A shield that
uses SPI on D10 to D13 needs a design that connects the SPI controller to `ar[10]` to `ar[13]`.

### Power header J7 and `AR_RST`

| J7 pin | Arduino name | Net |
|---|---|---|
| 1 | VIN | `VU_CK` |
| 2, 3 | GND | ground |
| 4 | 5V | `VCC5V0` |
| 5 | 3.3V | `VCC3V3` |
| 6 | RESET | `AR_RST` |
| 7 | IOREF | `VCC3V3` |
| 8 | (none) | not connected |

**[schematic] sheet 4.** `VU_CK` is the supply `VU` after the switch Q14 (`AP2307GN`)
**[schematic] sheet 15**. The manual says that a battery can supply the board on this pin, with the
jumper J9 on REG **[manual]**. See [power.md](power.md).

`AR_RST` goes to MIO12 (D9) of the PS. Q9 (`NC7WZ07P6X`, an open-drain buffer) pulls it low while
the button SRST1 is pushed, and R236 (10 kohm) pulls it up to `VCC3V3` **[schematic] sheet 10**.
Thus a shield sees a reset while SRST1 is pushed. The PS can also drive or read the line through
MIO12.

### Analog inputs A0 to A5

The header pins A0 to A5 (J1) have two uses **[schematic] sheets 4, 11**:

- **Digital.** Each pin goes directly to a PL pin (no series resistor): ports `a[0]` to `a[5]` on
  Y11, Y12, W11, V11, T5 and U10 (bank 13).
- **Analog.** Each pin also has a divider to ground: 2.32 kohm (R64, R66, R68 to R71) and 1 kohm
  (R100 to R105). The middle of the divider goes through 140 ohm to an auxiliary input of the XADC
  (`AR_ANx_P`). The `_N` input goes through 845 ohm to ground. A 1000 pF capacitor (C3 to C8) is
  between `_P` and `_N`.

The divider gives 1 / 3.32 of the input: 3.3 V at the header gives about 0.99 V at the XADC (a
calculation from the resistor values). The manual gives an input range of 0 to 3.3 V **[manual]**.
The divider is also a load of 3.32 kohm to ground on the digital pin.

| Header pin | Digital pin, port | XADC input | `_P` pin | `_N` pin |
|---|---|---|---|---|
| A0 | Y11, `a[0]` | VAUX1 | E17 `ar_an0_p` | D18 `ar_an0_n` |
| A1 | Y12, `a[1]` | VAUX9 | E18 `ar_an1_p` | E19 `ar_an1_n` |
| A2 | W11, `a[2]` | VAUX6 | K14 `ar_an2_p` | J14 `ar_an2_n` |
| A3 | V11, `a[3]` | VAUX15 | K16 `ar_an3_p` | J16 `ar_an3_n` |
| A4 | T5, `a[4]` | VAUX5 | J20 `ar_an4_p` | H20 `ar_an4_n` |
| A5 | U10, `a[5]` | VAUX13 | G19 `ar_an5_p` | G20 `ar_an5_n` |

The `AR_AN*` pins are in bank 35. The XADC channel numbers come from the pin function names
(`AD1P`, `AD9P` and so on) of sheet 11. The board file has no interface for these pins.

The manual also says that six of `AR0` to `AR13` can be differential analog inputs **[manual]**.
The schematic does not show this: `AR_IO0` to `AR_IO13` are on bank 34 pins without an `AD`
function.

### XADC header J5

J5 (1x4) has `XADC_V_P` (1), `XADC_V_N` (2), `XADCGND` (3) and `XADCVREF` (4) **[schematic] sheet 4**.
`XADC_V_P` and `XADC_V_N` go through 140 ohm (R214, R215) to the dedicated inputs VP_0 (K9) and VN_0
(L10). C72 (0.1 µF) is between them **[schematic] sheet 9**. These pins cannot be digital I/O. See
[fpga.md](fpga.md).

The manual says that the 1 nF capacitor is fitted only on V_P/V_N **[manual]**. The schematic shows
0.1 µF on V_P/V_N and 1000 pF on each of A0 to A5.

## Differences between the sources

- **Raspberry Pi pin table of the manual.** The manual gives other FPGA pins for RPi pins 7, 8, 10,
  18, 22, 26, 29 and 31 **[manual]**. For example it puts V6 on pin 7 and Y18 on pin 8. The
  schematic R12, the TUL XDC and the board file agree with each other and with the table above.
  The board agrees with them too **[measured]**: on 2026-11-24, a wire from GND on each of the eight
  header pins pulled the FPGA pin of the table above low (`tools/pinprobe/`, GND tap). Thus the
  manual table is wrong for this board. The revision history (sheet 2) records changes to the RPi
  header in revision B; the manual may describe an earlier revision.
- **The manual's PmodB table** gives `W156` for pin 8. The schematic gives W16.
- **I2C of the Arduino header**: the schematic net names and the TUL XDC are wrong; see above.
