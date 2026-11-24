# microSD card

SD1 is a microSD socket (`MicroSDCARD_8H`) on SDIO0 of the PS **[schematic]** sheets 5 and 10. The
manual gives the same controller and MIO pins.

| Signal | MIO | Path |
|---|---|---|
| `CLK` | 40 | Through R217 (40.2 Ω), then the level shifter U6 |
| `CMD` | 41 | U6 |
| `DAT0` to `DAT3` | 42 to 45 | U6 |
| `CD` | 47 | Directly from the socket switch, no level shifter |

The board preset enables SD0 on MIO40 to 45 with card detect on MIO47, at 50 MHz. It does not
enable write protect or a power control pin. The manual says that the controller does 1-bit and
4-bit SD transfers, and no SPI mode.

## Level shifter and voltage

U6 is marked `TXS02612RTWR` **[schematic]** sheet 5:

- Port A (`VCCA`) is on `VCC1V8`, the voltage of MIO bank 501.
- Port B0 (`VCCB0`) is on `VCC3V3`, and goes to the socket. Port B1 has no connection, and `VCCB1`
  is on `VCC3V3`. `SEL` has a 4.7 kΩ pull-down (R135). By the wiring, low on `SEL` selects port B0;
  the datasheet of U6 is not in `references/`.
- `VDD` of the socket is on `VCC3V3` directly. No switch can turn off the power of the card.

Thus the card always runs at 3.3 V signal level. The 1.8 V signal level of UHS-I is not possible:
neither the card supply nor the shifter can change. The maximum is High Speed at 50 MHz, the
limit that the manual gives.

## Card detect

The `Del_SW` contact of the socket (pin 9) goes through R134 (200 Ω) to `SD_CD` on MIO47. R133
(47 kΩ) pulls `SD_CD` up to `VCC1V8` **[schematic]** sheet 5. The other contact of the switch is not
on the sheet.

The card detect works with the default polarity of the controller **[measured]**. On 2026-11-24,
U-Boot reported no card while the slot was empty, and found the card while it was in the slot.
Linux also found the card without `cd-inverted` in the device tree. The voltage on MIO47 was not
measured.

## Test on the board

On 2026-11-24, Linux ran the card in SD High Speed mode: 50 MHz, 4 bits, 3.3 V signal level
**[measured]**. A read of 256 MiB with `dd bs=1M iflag=direct` gave 20.3 MB/s. The card was a 64
GB SDXC card that reported the name `SB64G`. The figure applies to that card only.

## Use

- The SD card is a boot medium in the SD position of JP1 (boot.md).
- Write a card only when the owner gives that card for writing. A card that holds the only boot
  image of the board needs a copy first.
