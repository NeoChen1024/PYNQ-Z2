# Clocks

| Clock | Destination | Source | Frequency | Evidence |
|---|---|---|---|---|
| `PS_CLK` | E7 (`PS_CLK_500`) | OSC3, marked `DSC1121CE5-50.0000`, through R222 (49.9 Ω) | 50 MHz | **[schematic]** sheet 10, **[manual]** |
| `ETH_CLK` | `CKXTAL1` of the Ethernet PHY U5 | The same OSC3, through R223 (49.9 Ω) | 50 MHz | **[schematic]** sheets 5 and 10 |
| `SYSCLK` | H16 (bank 35, `IO_L13P_T2_MRCC_35`) | `CLK125` output of the Ethernet PHY U5 | 125 MHz | **[schematic]** sheets 5 and 11, **[manual]** |
| `USB_OTG_RCLK` | `REFCLK` of the USB PHY U9 | OSC1, marked `26MHz_30pF`, through R172 (0 Ω) | 26 MHz | **[schematic]** sheet 7 |
| FT2232H crystal | `OSCI`/`OSCO` of U12 | Y1 | 12 MHz | **[schematic]** sheet 8 |

## PS_CLK

The board preset sets `PCW_CRYSTAL_PERIPHERAL_FREQMHZ` to 50. The PLLs of the PS make all PS clocks
from it: the CPU at 650 MHz, the DDR at 525 MHz, and the PL clock `FCLK_CLK0` at 100 MHz (ps.md).
The data sheet DS187 allows 30 to 60 MHz on `PS_CLK`.

## SYSCLK: the PL clock comes from the Ethernet PHY

The 125 MHz clock on H16 is not an oscillator. It is the `CLK125` output of the RTL8211E-VL PHY
**[schematic]** sheet 5. The manual says the same, and it adds this: while `PHYRSTB` is low, the
PHY is in reset and `CLK125` stops **[manual]**.

- `PHYRSTB` is `ETH_RST_B` on MIO9. R296 (4.7 kΩ) pulls it up to 3.3 V, with C114 (1 µF) to GND
  **[schematic]** sheet 5. Thus, after power-on and before software drives MIO9, the PHY runs.
- The board preset gives MIO9 to the ENET0 reset (`PCW_ENET0_RESET_IO`). Software that resets the
  PHY (the FSBL, U-Boot or Linux) stops `SYSCLK` for the time of the reset.
- A PL design that uses `SYSCLK` must not depend on it while the PS resets the PHY. If the design
  needs a clock that never stops, use `FCLK_CLK0` of the PS. Linux keeps `FCLK_CLK0` on only with
  `fclk-enable` in the device tree; without it, Linux stopped the clock (pl-interface.md).
- The PHY gives `CLK125` with its default settings **[measured]**. On 2026-11-24, pl-blinky
  counted on LD0 to LD3 from `SYSCLK`. No software had initialized the PS or the PHY.
- `SYSCLK` is 1.25000 times `FCLK_CLK0` **[measured]**. On 2026-11-26, pl-interface counted both
  for 1 s (pl-interface.md). Both come from OSC3, so this checks the dividers, not OSC3.
- A register write stops `CLK125`: bit 4 of PHYCR (register 0x10, page 0) is "Disable CLK125"
  (RTL8211E data sheet, Table 37, PDF page 49). On 2026-11-24 **[measured]**, U-Boot read PHYCR as
  0x016E. pinprobe counted the changes of its bit that `SYSCLK` divides by 2^23, for 8 s each:

  | PHYCR | Changes in 8 s |
  |---|---|
  | 0x016E (default) | 119 |
  | 0x017E (bit 4 set, with `mii write`) | 0 |
  | 0x016E (written back) | 119 |

  119 changes in 8 s are 14.9 per second, which agrees with 125 MHz / 2^23 to about 1 %.
- The RTL8211E data sheet does not say whether `CLK125` stops while `PHYRSTB` is low. The manual
  says that it stops.

The master XDC has the clock constraint for it: `create_clock -period 8.00` on `sysclk`.

## Other clocks

No other oscillator connects to the PL. The audio codec takes its master clock `AU_MCLK_R` from the
PL (audio.md). The HDMI ports have no clock source on the board (hdmi.md).
