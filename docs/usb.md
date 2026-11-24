# USB host

The USB port for devices is a type-A receptacle, USB_1 (`USB_4H`) **[schematic]** sheet 7. It is
not the micro-USB J8: that one is the USB-JTAG and UART (jtag-uart.md).

## PHY

U9 is a ULPI PHY marked `TUSB1210BRHBR` **[schematic]** sheet 7. The manual gives a TI TUSB1210,
USB 2.0, connected to USB0 of the PS.

| Signal | MIO | Note |
|---|---|---|
| `DATA0` to `DATA7` | 32, 33, 34, 35, 28, 37, 38, 39 | `DATA4` is on MIO28 |
| `DIR`, `STP`, `NXT` | 29, 30, 31 | |
| `CLK` (from the PHY) | 36 | |
| `RESETB` (`OTG_RESETN`) | 46 | 1 kΩ pull-up (R171) to `VCC1V8` |

**[schematic]** sheets 7 and 10, MIO bank 501 at 1.8 V. The board preset enables USB0 on MIO28 to 39,
with the PHY reset on MIO46, active low.

- `REFCLK` of U9 takes 26 MHz from the oscillator OSC1 (clocks.md).
- `VDDIO` and the `VDD18` pins of U9 are on `VCC1V8`. `VDD33` is on `VCC3V3`.
- The `ID` pin of U9 is on GND. Thus the PHY is always the A-device (host).

## VBUS

U10, marked `TPS2065DB`, switches `VCC5V0` to `USB_OTG_VBUS` on the connector **[schematic]**
sheet 7:

- Its enable is `CPEN` of U9, with a 4.7 kΩ pull-down (R175). The USB controller turns VBUS on
  through the PHY. The PHY drives `CPEN` only if software sets `DrvVbusExternal` (bit 6) in its OTG
  Control register (ULPI address 0x0A) **[measured]**. On 2026-11-24, the OTG Control register
  read 0x27 after Linux started the host: `DrvVbus` set, `DrvVbusExternal` clear. VBUS was off, and
  the port found no device. A write of 0x40 to address 0x0B (the set address of OTG Control) turned
  VBUS on, and the controller found the USB device at once.
- Its over-current output `OC#` is `OTG_OC` on MIO11. The board preset sets MIO11 as GPIO.
- `USB_OTG_VBUS` also goes to the `VBUS` pin of U9.

The current limit of U10 is in its datasheet, which is not in `references/`.

## Test on the board

On 2026-11-24 **[measured]**:

- The ULPI registers 0 to 3 of U9 read 0x51, 0x04, 0x07, 0x15: vendor 0x0451 (TI), product 0x1507.
- Linux 6.18.64 with the changes of linux/README.md ("USB host") found a USB flash drive at boot.
  It was a full-speed device (`wch.cn USB-Mini-Disk`, 256 KiB), and two reads of the whole device
  gave the same MD5 sum.
- A high-speed device was not tested. The current limit and the over-current flag on MIO11 were not
  tested.

## Mode

The manual says that the port is a host only: device mode and OTG are not supported. The schematic
agrees: the connector is type A, and `ID` is on GND. Linux needs `dr_mode = "host"` for the USB0
node. A USB device on the port takes its power from `VCC5V0` (power.md). With USB power from J8,
that power comes from the host of J8.
