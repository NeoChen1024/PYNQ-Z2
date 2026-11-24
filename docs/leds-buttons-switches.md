# LEDs, buttons, switches

All the user LEDs, buttons and switches connect to PL pins in banks 34 and 35 at 3.3 V
**[schematic] sheets 3, 11, 12**. The ports are those of `pynq_z2_master.xdc`. Use `LVCMOS33`.

## LEDs LD0 to LD3

| LED | Net | Pin | Bank | Port |
|---|---|---|---|---|
| LD0 | `LED0` | R14 | 34 | `led[0]` |
| LD1 | `LED1` | P14 | 34 | `led[1]` |
| LD2 | `LED2` | N16 | 35 | `led[2]` |
| LD3 | `LED3` | M14 | 35 | `led[3]` |

Each pin drives the anode of an LED (marking `SML-010-L`) through 330 ohm (R48, R45, R42, R39). The
cathode is on ground. **A high output lights the LED** **[schematic] sheet 3** **[manual]**.

## RGB LEDs LD4 and LD5

| Colour | LD4 pin | LD4 port | LD5 pin | LD5 port |
|---|---|---|---|---|
| Blue | L15 | `led4_b` | G14 | `led5_b` |
| Green | G17 | `led4_g` | L14 | `led5_g` |
| Red | N15 | `led4_r` | M15 | `led5_r` |

All six pins are in bank 35 **[schematic] sheets 3, 11**.

The circuit, **[schematic] sheet 3**:

- The anodes of the LED get `VCC5V0` through one resistor for each colour: 86.6 ohm (blue), 150 ohm
  (red) and 75 ohm (green).
- An NPN transistor (marking `PMBS3904`, Q1 to Q6) switches each cathode to ground.
- The PL pin drives the base through 2.2 kohm. A second 2.2 kohm holds the base at ground.

Thus **a high output lights the colour**, and an undriven pin leaves it off. The manual says that the
transistor inverts the signal. That is true of the cathode voltage, not of the logic of the pin.
The manual recommends PWM for these LEDs, because they are bright **[manual]**.

## Buttons BTN0 to BTN3

| Button | Pin | Port |
|---|---|---|
| BTN0 | D19 | `btn[0]` |
| BTN1 | D20 | `btn[1]` |
| BTN2 | L20 | `btn[2]` |
| BTN3 | L19 | `btn[3]` |

All four pins are in bank 35. Each button (marking `PTA-142`) connects `VCC3V3` to its net. A 10
kohm resistor holds the net at ground, and a second 10 kohm goes in series to the pin. **A pushed
button reads high** **[schematic] sheet 3** **[manual]**. The board has no debounce circuit. The
design must debounce the buttons.

The revision history of the schematic (sheet 2, revision B) says that the pin definition of BTN1 to
BTN4 changed. The table above is the R12 state.

## Slide switches SW0 and SW1

| Switch | Pin | Port |
|---|---|---|
| SW0 | M20 | `sw[0]` |
| SW1 | M19 | `sw[1]` |

Both pins are in bank 35. Each switch (marking `sw-3P-102-1221`) has three pins: pin 3 on `VCC3V3`,
pin 1 on ground, and the common pin 2. Pin 2 goes to the PL pin through 10 kohm (R44, R37)
**[schematic] sheet 3**. Thus the pin is always at a defined level. The manual says that the "up"
position gives a high level **[manual]**.

## LEDs that the PL does not drive

- **DONE (CR7)**: `VCC3V3` goes through R210 (220 ohm) to `DONE_0` of the FPGA, and from there
  through R211 (220 ohm) and the LED CR7 to ground **[schematic] sheet 9**. The LED is on while
  `DONE_0` is high, that is, while the PL is configured.
- The manual names LEDs for power, USB and Ethernet as well **[manual]**. See [power.md](power.md),
  [usb.md](usb.md) and [ethernet.md](ethernet.md).

## Reset and PROG buttons

The board also has the buttons SRST1 (system reset of the PS) and PROG1 (`PROGRAM_B` of the PL)
**[schematic] sheets 9, 10**. They do not go to user PL pins. See [boot.md](boot.md). SRST1 also
pulls `AR_RST` of the Arduino header low ([headers.md](headers.md)).

## Test on the board

On 2026-11-24, `examples/pl-blinky` ran on the board, loaded over JTAG **[measured]**. The owner
saw this:

- LD0 to LD3 counted, with LD0 the fastest.
- SW0 made the count slower, and SW1 inverted the four LEDs.
- BTN0, BTN1 and BTN2 lit red, green and blue of LD4. BTN3 lit red of LD5.

Thus the pins and the polarities of the tables above are correct for these parts.

While the PL is not configured or is being configured, the I/O pins have weak pull-ups
(headers.md). The owner saw LD0 to LD3 glow weakly during configuration (2026-11-24). The green and
blue colors of LD5 were not tested.
