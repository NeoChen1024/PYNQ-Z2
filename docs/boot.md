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
high. No jumper position connects pin 4 to 3.3 V. The VCFG values agree with the bank voltages on
sheet 12 and with the board preset.

UG585 (`references/amd/ug585-Zynq-7000-TRM_v1.7.pdf`), Table 6-4 (page 164), gives the meaning of the straps:

| MIO | Strap | Low | High |
|---|---|---|---|
| 2 | `BOOT_MODE[3]` | JTAG chain in cascade mode (the PL TAP and the ARM DAP in one chain) | Independent mode |
| 3, 4, 5 | `BOOT_MODE[1]`, `BOOT_MODE[2]`, `BOOT_MODE[0]` | See below | |
| 6 | `BOOT_MODE[4]` | PS PLLs on | PS PLLs bypassed |
| 7, 8 | `VMODE[0]`, `VMODE[1]` | Bank 500 / 501 at 2.5 V or 3.3 V | At 1.8 V |

`BOOT_MODE[2:0]` (MIO4, MIO3, MIO5) selects the boot device: 000 JTAG, 001 QSPI, 101 SD; NOR and
NAND need MIO3 high, which this board does not allow. Thus the three JP1 positions give JTAG (0),
QSPI (1) and SD (5). The board holds MIO2 and MIO6 low: cascade JTAG and PLLs on. The JTAG chain
that `hw_server` shows (jtag-uart.md) is the cascade chain.

The straps are read only at power-on reset (`PS_POR_B`). UG585, page 161 and Table 6-3 (page 162),
says that a system reset (`PS_SRST_B`, the SRST button) keeps the previous boot mode, runs the boot
ROM again and resets the PL. The manual says the same **[manual]**. UG585, page 161, also warns: a
system reset while the boot ROM runs after a power-on reset locks the system until the next
power-on reset.

On 2026-11-24, JP1 was in the SD position and no card was in the slot. The register `BOOT_MODE`
(0xF800025C) read 0x5 over JTAG **[measured]**. By UG585, Appendix B (page 1607), bit 4 is
`PLL_BYPASS` (0) and bits 3 to 0 are the straps: cascade JTAG and SD boot. The JTAG and QSPI
positions were not read.

If the boot ROM finds no boot image on the card, it goes into a non-secure lockdown: it clears the
PL, enables JTAG and stops both CPUs in WFE (UG585, pages 167, 189 and 194; error 0x200A on page
190). Thus a JTAG boot works in SD mode with no card, as on 2026-11-24 (jtag-uart.md). Which error
code the boot ROM sets with no card at all was not read (`REBOOT_STATUS`).

## QSPI flash U16

**[schematic]** sheet 9:

- U16 is marked `S25FL128SAGMFI00` on the schematic. The manual gives a Spansion S25FL128S, 16 MB,
  at 3.3 V. The fitted chip has `SPANSION` and `FL128SAIF00` on it (seen 2026-11-24). U-Boot read
  the JEDEC ID `01 20 18 4D 01 80` and found an S25FL128S **[measured]**.
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

On 2026-11-24, U-Boot read the OTP area with the command OTP Read (0x4B) **[measured]**. The reads
used `sspi` of a test build of U-Boot (`CONFIG_CMD_SPI`), loaded over JTAG. Two reads gave the
same data:

| OTP address | Contents |
|---|---|
| 0x00 to 0x0F | 16 bytes that are not all 0xFF: the 128-bit random number that the flash maker programs |
| 0x10 to 0x13 | 0xFF: the lock bits of the 32 OTP regions, all unlocked |
| 0x14 to 0x1F | 0xFF: reserved |
| 0x20 to 0x25 | A 6-byte value. Its first three bytes are an OUI of the IEEE register (`C.P. Technology Co., Ltd.`), and it is a globally unique unicast address |
| 0x26 to 0x4A | 0xFF |

Thus the board has a unique MAC address at 0x20 to 0x25, as the manual says. The record does not
give the value, because it is the address of the owner's board on the LAN (AGENTS.md).

The S25FL128S data sheet (`references/infineon/s25fl128s-s25fl256s_001-98283_RevT.pdf`, section
7.4, page 49, and Table 22, page 50) describes the OTP area:

- It has 1024 bytes in 32 regions of 32 bytes. The MAC address is in region 1 (0x20 to 0x3F).
- Bytes 0x10 to 0x13 are the lock bits, one for each region. A bit at 0 locks its region. All
  bits read 1, so **no region is locked**, also not region 1.
- A program can still change a 1 to a 0 in region 1 (section 11.7.1, page 118). The OTP area can
  never be erased (section 10.1.2, page 63). Thus a wrong OTP write destroys the MAC address for
  ever. This is why the record never writes the OTP area.
- The data sheet does not say that the random number of 0x00 to 0x0F is unique (section 10.1.3,
  page 63).
- OTP Read (0x4B) has a 3-byte address and always one dummy byte (section 11.7.2, page 118).

The marking `FL128SAIF00` is the short form of `S25FL128SAGMFI00`: 128 Mbit, 133 MHz, SO-16
package, industrial temperature, uniform 64 KB sectors with 4 KB parameter sectors (Table 86,
page 155). The JEDEC ID `01 20 18 4D 01 80` agrees: Spansion, 128 Mbit, 64 KB sectors (byte 5 is
01), FL-S family (Table 56, page 129).

## Boot images

- The boot image is `BOOT.BIN`: the FSBL, an optional bitstream, and the next program (for example
  U-Boot). `bootgen` makes it from a `.bif` file. The Zynq Book, chapter 24, describes the image
  and the boot stages.
- In SD mode the boot image is the file `BOOT.BIN` on the card. In QSPI mode it is in U16. The
  partition and offset rules of the boot ROM are in UG585, chapter 6.
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
