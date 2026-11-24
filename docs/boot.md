# Boot and configuration

The PS starts first. Its boot ROM reads the boot mode straps on MIO2 to MIO8 at power-on reset, and
then loads the first-stage boot loader from the medium that the straps select. The boot loader then
configures the PL, if the boot image has a bitstream.

## Boot mode jumper JP1

JP1 is a 4-pin header with one jumper **[schematic]** sheet 10. The silkscreen drawing on the sheet
shows three positions. The manual names the same three modes.

| JP1 position | MIO5 (`MODE0`) | MIO4 (`MODE2`) | Mode on the drawing |
|---|---|---|---|
| 1-2 | Low (pin 2 is GND) | Low (R233, 1 kΩ to GND) | JTAG |
| 2-3 | High (R224, 1 kΩ to 3.3 V) | Low | QSPI |
| 3-4 | High | High (pin 4 is 3.3 V) | SD |

Each strap node connects to its MIO pin through 20 kΩ (R226, R229). The other straps are fixed:

| MIO | Net | Strap | Value |
|---|---|---|---|
| 2 | `SPI_DQ0/MODE3` | R228 (20 kΩ) to a node with R227 (1 kΩ) to GND | Low. JTAG_JP1 pins 1-2 can pull it high |
| 3 | `SPI_DQ1/MODE1` | R234 (20 kΩ) to GND | Low |
| 6 | `SPI_SCK/MODE4` | R232 (20 kΩ) to a node with R231 (1 kΩ) to GND | Low |
| 7 | `VCFG0` | R230 (20 kΩ) to GND | Low: MIO bank 500 at 3.3 V |
| 8 | `SPI_SCLK_FB/VCFG1` | R225 (20 kΩ) to 3.3 V | High: MIO bank 501 at 1.8 V |

**[schematic]** sheet 10. JTAG_JP1 is a 4-pin header: pin 1 is `VCC3V3`, pin 2 goes to the MIO2
node, pin 3 has no connection, and pin 4 goes to the MIO6 node. A jumper on pins 1-2 sets MIO2
high. No jumper position connects pin 4 to 3.3 V. The meaning of MIO2 and MIO6 as boot straps is in
the Zynq-7000 Technical Reference Manual (UG585), which is not in `references/`. The VCFG values
agree with the bank voltages on sheet 12 and with the board preset.

The straps are read only at power-on reset. The manual says that the SRST button does not read
them again **[manual]**.

On 2026-11-24, JP1 was in the SD position and no card was in the slot. The register `BOOT_MODE`
(0xF800025C) read 0x5 over JTAG **[measured]**. Its low three bits are 101. This agrees with MODE2,
MODE1 and MODE0 at high, low and high, the strap values of the SD position in the table above.

## QSPI flash U16

**[schematic]** sheet 9:

- U16 is marked `S25FL128SAGMFI00`. The manual gives a Spansion S25FL128S, 16 MB, at 3.3 V.
- It connects to MIO1 to MIO6 (`CS`, `DQ0` to `DQ3`, `SCK`), which is the QSPI0 single-device mode
  of the board preset. MIO6 goes through R221 (0 Ω).
- `CS#` has a 4.7 kΩ pull-up (R212). `RESET#` and `VCC` are on `VCC3V3`.
- MIO8 is the QSPI feedback clock (`PCW_QSPI_GRP_FBCLK_IO`). It has only the 20 kΩ strap pull-up.
  The manual says that feedback mode lets the QSPI clock go above the limit without feedback.
- The board preset runs the QSPI controller at 200 MHz (`PCW_QSPI_PERIPHERAL_FREQMHZ`). The
  controller divides it for the flash clock.

The manual says that a one-time-programmable area of the flash holds a unique 48-bit identifier
at OTP addresses 0x20 to 0x25. PYNQ uses it as the MAC address (ethernet.md). Never write the OTP
area: the identifier cannot be restored.

## Boot images

- The boot image is `BOOT.BIN`: the FSBL, an optional bitstream, and the next program (for example
  U-Boot). `bootgen` makes it from a `.bif` file. The Zynq Book, chapter 24, describes the image
  and the boot stages.
- In SD mode the boot image is the file `BOOT.BIN` on the card. In QSPI mode it is in U16. The
  partition and offset rules of the boot ROM are in UG585, which is not in `references/`.
- In JTAG mode the boot ROM loads nothing. The host loads the PS and the PL through JTAG with
  Vivado or `xsdb`. A JTAG load is gone at power-off. It does not touch U16 or the SD card.
- A PL-only bitstream can also load through JTAG in QSPI or SD mode, after the PS has booted.

## Resets of the configuration

**[schematic]** sheets 9 and 10:

- The button PROG1 pulls `PROGRAM_B` low. The PL loses its configuration and `DONE` goes low. The PS
  continues to run. The PL stays empty until the PS or JTAG loads it again **[manual]**.
- The button SRST1 resets the PS through `PS_SRST_B` (ps.md).

## Safety

- Write U16 only when the owner asks for that write. The flash can hold the only boot image of the
  board.
- Write an SD card only when the owner gives that card for writing.
- Prefer a JTAG load for a test. It does not change any medium.
