# Not known

These questions are open. Each line names the document that raises it. A change that answers a
question removes it here and updates that document.

## Board and parts

- Which revision of the schematic the board follows. The file is named R12, its PDF title says
  `r11_0109`, and the title blocks say R10 (2018-01-09). The board has no revision mark on its
  back. (fpga.md)
- What `/X` on the schematic means. U14, J13, J14 and JP2 are not fitted, but JP3 is fitted (seen
  2026-11-24). Thus `/X` does not always mean "not fitted". R208, R209, R139 to R146, R299 and C19
  were not checked. (crypto.md, hdmi.md, jtag-uart.md, power.md)
- The power-up order of the four outputs of the TPS65400. (power.md)
- How much timing margin the DDR3 has with the negative DQS-to-CLK delays of the board preset,
  about which Vivado warns. One pass of a memory test found no error. (ps.md)

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

- Whether a register write to the Ethernet PHY can stop `CLK125`. (clocks.md)
- How the Zynq decodes the boot mode straps on MIO2 to MIO8. The decoding is in UG585, which is not
  in `references/`. (boot.md)
- What the bytes 0x10 to 0x13 of the OTP area of the QSPI flash are. They read 0xFF. The data
  sheet of the S25FL128S is not in `references/`. (boot.md)
- What the straps TXDLY, RXDLY, SELRGV, AN0 and AN1 of the RTL8211E select. Its datasheet is not in
  `references/`. (ethernet.md)
- The I2C address of the audio codec. The ADAU1761 datasheet is not in `references/`. (audio.md)

## Host side

- Whether `hw_server` needs the strings in the user area of the FT2232H EEPROM to find the board.
  (jtag-uart.md)
