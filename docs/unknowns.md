# Not known

These questions are open. Each line names the document that raises it. A change that answers a
question removes it here and updates that document.

## Board and parts

- Which revision of the schematic the board follows. The file is named R12, its PDF title says
  `r11_0109`, and the title blocks say R10 (2018-01-09). The board has no revision mark on its
  back. (fpga.md)
- What `/X` on the schematic means. U14, J13, J14, JP2, R180 and R209 are not fitted, but JP3 is
  fitted (2026-11-24). Thus `/X` does not always mean "not fitted". R208, R299 and C19 were not
  checked; R139 to R146 are probably the empty footprints beside `HDMI_IN`. (crypto.md, hdmi.md,
  jtag-uart.md, power.md, audio.md)
- The power-up order of the four outputs of the TPS65400. With its factory EEPROM, they start
  together; whether TUL changed the EEPROM is not known. A measurement of the rails would show it.
  (power.md)
- How much timing margin the DDR3 has with the negative DQS-to-CLK delays of the board preset,
  about which Vivado warns. One pass of a memory test found no error. (ps.md)

## Pins and headers

- Whether the I/O pull-ups are on during configuration. U13 (`PUDC_B`) has no external pull, so it
  floats if nothing is on Arduino AR2. (headers.md)
- Whether R299 is fitted. The HPD of `HDMI_IN` works in each test, so the owner thinks that R299
  is fitted and that its `/X` is a mistake of the schematic. Not seen. (hdmi.md)

## Clocks, boot and PS

- Whether a write of PHYCR bit 4 stops `CLK125` on the board, as the data sheet says. (clocks.md)
- `BOOT_MODE` in the JTAG and QSPI positions of JP1 was not read. UG585 gives 0x0 and 0x1. (boot.md)
- Which signal from the PL to the PS stops Linux when a bitstream without a PS7 cell is loaded.
  CPU0 was in the FIQ handler. (vivado.md)

## Host side

- Whether `hw_server` needs the strings in the user area of the FT2232H EEPROM to find the board.
  (jtag-uart.md)
