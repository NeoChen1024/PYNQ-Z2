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
- Why the board made a power-on reset while Linux was idle on USB power (2026-11-25). The input
  must fall to about 3.5 V for this, but an inline USB meter showed at least 4.88 V at full load.
  A meter that keeps the minimum voltage, or the fault bits of the TPS65400 through JP2, would show
  more. (power.md)

## Pins and headers

- Whether R299 is fitted. The HPD of `HDMI_IN` works in each test, so the owner thinks that R299
  is fitted and that its `/X` is a mistake of the schematic. Not seen. (hdmi.md)

## Clocks, boot and PS

- Why bit 0 of `FPGA0_THR_CNT` (0xF8000178) stops `FCLK_CLK0`. Linux uses it as the gate of the
  clock, and a write of 1 stopped the clock. UG585 (page 1584) describes the register as the count
  of the clock throttle. (pl-interface.md)
- Whether a read in the GP0 window stops the PS when no PL design answers it. Not tested, because
  it can stop the board. (pl-interface.md)
- Whether a transfer between the CPU and the PL fails without `dsb` before the start. The test
  always used `dsb`. (pl-interface.md)
- What an HP access above 0x1FFF_FFFF does on this board with 512 MiB. (pl-interface.md)
- Whether an HP port with 32-bit data works after a write to its AFI registers. Not tested.
  (pl-interface.md)

- How the FIQ from the PL (`IRQF2P[18]`) reaches CPU0 while `ICCICR` is 0x1. UG585 says that the
  pass-through is used only when `ICCICR[1:0]` is 0. (vivado.md)
