# USB-JTAG and UART

The micro-USB connector J8 (`PROG UART` on the board, by the manual) goes to U12, a two-channel
USB bridge marked `FT2232HL` **[schematic]** sheet 8. The manual gives an FTDI FT2232HL. One cable
gives the JTAG of the SoC, the console UART of the PS, and 5 V power (power.md).

## The two channels of U12

**[schematic]** sheet 8:

| U12 pins | Net | Destination |
|---|---|---|
| `ADBUS0` (16) | `FT2232_TCK` → `TCK` | `TCK_0` (F9) |
| `ADBUS1` (17) | `FT2232_TDI` → `TDO_USB/TDI_FPGA` | `TDI_0` (G6) |
| `ADBUS2` (18) | `FT2232_TDO` ← `TDI_USB/TDO_FPGA` | `TDO_0` (F6) |
| `ADBUS3` (19) | `FT2232_TMS` → `TMS` | `TMS_0` (J6) |
| `BDBUS0` (38) | `FT2232H_UART_TX` → `UART_TXD_IN` | MIO14 (C5), the RX of PS UART0 |
| `BDBUS1` (39) | `FT2232H_UART_RX` ← `UART_RXD_OUT` | MIO15 (C8), the TX of PS UART0 |

- Channel A is the JTAG. Each JTAG line goes through 0 Ω (R316 to R319) and has a 4.7 kΩ pull-up to
  `VCC3V3` (R300, R313, R314, R315).
- Channel B is the UART. Only TX and RX connect. There is no RTS, CTS or DTR.
- The two LEDs D17 and D18 show the UART traffic (`FT2232H_LED_RX`, `FT2232H_LED_TX`).
- U13, marked `93AA56B`, is the configuration EEPROM of U12. Its contents are not known.
- U12 runs from `VCC3V3` of the board, and its `RESET#` is on `EN_MAIN` through R193 (1 kΩ). Thus
  the host sees the bridge only while the power switch is on (power.md).
- Y1 is the 12 MHz crystal of U12.

## UART

The board preset puts PS UART0 on MIO14 (RX) and MIO15 (TX) at 115200 baud
(`PCW_UART0_BAUD_RATE`). MIO bank 500 is at 3.3 V, the same level as `VCCIO` of U12.

On a Linux host, U12 gives two serial devices. Which `ttyUSB` number is the UART was not
measured. Channel B (the second interface) has the UART by the schematic.

The 2-pin header J13 has `UART_RXD_OUT` and `UART_TXD_IN`, for an external UART adapter. The
schematic marks it `/X`.

## External JTAG header

JP3 is a 4-pin header with `TMS`, `TDI`, `TDO` and `TCK`, each through 100 Ω (R204 to R207), with the
ESD diodes D8 to D11 **[schematic]** sheet 9. J14 next to it has `VCC3V3` and GND. The schematic
marks both headers `/X`. If an external cable drives JP3, U12 also drives the same JTAG lines.

## Use with Vivado

Whether Vivado `hw_server` and `openFPGALoader` find this board without setup was not measured
(unknowns.md). The devices in the JTAG chain were not read yet. MIO2 (`MODE3`) is a boot strap that
the board holds low by default (boot.md).
