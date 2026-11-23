# Not known

These questions are open. Each line names the document that raises it. A change that answers a
question removes it here and updates that document.

## Board and parts

- Which revision of the schematic the board follows. The file is named R12, its PDF title says
  `r11_0109`, and the title blocks say R10 (2018-01-09). (fpga.md)
- What `/X` on the schematic means. The record assumes "not fitted". It applies to U14, R208, R209,
  R139 to R146, R299, JP2, JP3, J13, J14 and C19. (crypto.md, hdmi.md, jtag-uart.md, power.md)
- Whether U14, the ATSHA204A crypto chip, is fitted. (crypto.md)
- Which DDR3 chip is fitted. The schematic marks `MT41K512M16HA-125:A` (512M x 16), the manual says
  256M x 16, and `preset.xml` uses `MT41J256M16 RE-125`. The marking on the board was not read.
  (ps.md)
- The power-up order of the four outputs of the TPS65400. (power.md)
- Whether the DDR3 works reliably with the negative DQS-to-CLK delays of the board preset, about
  which Vivado warns. (ps.md)

## Pins and headers

- Which Arduino I2C line is SDA. The schematic and the TUL XDC give `AR_SDA` on P15 (J3.10). The
  manual and the board file give SDA on P16 (J3.9), which is the SDA position of an Arduino Uno R3.
  (headers.md)
- Whether the RPi table of the manual describes an earlier board. It gives other FPGA pins for RPi
  pins 7, 8, 10, 18, 22, 26, 29 and 31 than the schematic, the TUL XDC and the board file.
  (headers.md)
- What U13 (`PUDC_B`) does at configuration if nothing is connected to Arduino AR2. The schematic
  shows no pull resistor on it. (headers.md)
- What V5 connects to. The revision history of the schematic names it `AU_RESET`; sheet 11 shows no
  net. (audio.md)
- Whether the output enable of Q7, the HPD buffer of `HDMI_IN`, floats when R299 (`/X`) is not
  fitted. (hdmi.md)

## Clocks, boot and PS

- Whether `CLK125` of the Ethernet PHY runs with the default settings of the PHY, and whether
  software can stop it. (clocks.md)
- How the Zynq decodes the boot mode straps on MIO2 to MIO8. The decoding is in UG585, which is not
  in `references/`. (boot.md)
- The MDIO address 1 and the MAC address in the OTP come from the manual only. They were not read on
  the board. (ethernet.md, boot.md)
- What the straps TXDLY, RXDLY, SELRGV, AN0 and AN1 of the RTL8211E select. Its datasheet is not in
  `references/`. (ethernet.md)
- The polarity of the card-detect switch of SD1. Its other contact is not on the sheet.
  (sd-card.md)
- The I2C address of the audio codec. The ADAU1761 datasheet is not in `references/`. (audio.md)

## Host side

- Whether Vivado `hw_server` and openFPGALoader find the FT2232H without setup, and what its
  93AA56B EEPROM holds. (jtag-uart.md)
- Which `ttyUSB` number the PS UART gets on a Linux host. (jtag-uart.md)
