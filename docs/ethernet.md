# Ethernet

The board has one Gigabit Ethernet port. U5 is the PHY, marked `RTL8211E-VL`, and LAN1 is an RJ-45
jack with magnetics and two LEDs **[schematic]** sheet 5. The manual gives a Realtek RTL8211E-VL,
10/100/1000 Mb/s.

## Connection to the PS

The PHY connects to GEM0 of the PS through RGMII on MIO bank 501 (1.8 V):

| Signal | MIO | Note |
|---|---|---|
| `TXCK`, `TXD0` to `TXD3`, `TXCTL` | 16 to 21 | Direct |
| `RXCK`, `RXD0` to `RXD3`, `RXCTL` | 22 to 27 | Each through 0 Ω (R111, R116 to R120) |
| `MDC`, `MDIO` | 52, 53 | `MDIO` has a 1.5 kΩ pull-up (R122) to `ETH_VCC1V8` |
| `PHYRSTB` (`ETH_RST_B`) | 9 (bank 500, 3.3 V) | 4.7 kΩ pull-up (R296) to 3.3 V, 1 µF (C114) to GND |
| `INTB` (`ETH_INT_B`) | 10 (bank 500, 3.3 V) | |

**[schematic]** sheets 5 and 10. The board preset enables ENET0 on MIO16 to 27 with MDIO on MIO52/53,
and the PHY reset on MIO9, active low. It sets MIO10 as GPIO.

The PHY answers at MDIO address 1 **[measured]**. On 2026-11-24, U-Boot 2026.10 read it over
MDIO after `ps7_init`:

- `mii info` found the PHY at address 1 and also at address 0, with the same identifier.
- Registers 2 and 3 read 0x001C and 0xC915: OUI 0x0732, model 0x11, revision 5.
- The Linux driver `realtek` gives the identifier 0x001CC915 to the RTL8211E. This agrees with the
  marking.
- Register 1 (status) read 0x7949. No cable was connected, so the link was down.

On 2026-11-24, Linux 6.18.64 ran the port with `phy-mode = "rgmii-id"` **[measured]**. The
`realtek` driver (`RTL8211E Gigabit Ethernet`) linked at 1000 Mb/s full duplex on the LAN.
DHCP, NTP and SSH worked, with 0 receive and 0 transmit errors. The throughput was not measured.

## Supplies and clocks

**[schematic]** sheet 5:

- `ETH_VCC1V8` (from `VCC1V8` through the ferrite B17) supplies the I/O pins of U5 that face the
  SoC. Thus the RGMII is at 1.8 V, the same as MIO bank 501.
- `ETH_AVDD3V3` (from `VCC3V3` through B1, B2) and `ETH_VCC1V0` (from `VCC1V0` through B3) are the
  other supplies. `ENSWREG` is on GND: the internal regulator of the PHY is not used.
- `CKXTAL1` takes the 50 MHz `ETH_CLK` from the oscillator OSC3, which also clocks the PS
  (clocks.md). The manual says the same.
- `CLK125` is the `SYSCLK` of the PL on H16. It stops while `PHYRSTB` is low (clocks.md).
- `RSET` has 2.49 kΩ (R128) to GND.

## Strap resistors

The PHY reads its configuration from these pins at reset **[schematic]** sheet 5:

| U5 pin | Function | Resistor |
|---|---|---|
| 14, 16, 17, 18 | `RXD0/SELRGV`, `RXD1/TXDLY`, `RXD2/AN0`, `RXD3/AN1` | 4.7 kΩ pull-up each (R112 to R115) to `ETH_VCC1V8` |
| 13 | `RXCTL/PHY_AD2` | 4.7 kΩ (R121) to GND |
| 34 | `LED0/PHY_AD0` | 4.7 kΩ (R123) pull-up to `VCC3V3` |
| 35 | `LED1/PHY_AD1` | 4.7 kΩ (R129) to GND |
| 32 | `LED2/RXDLY` | 4.7 kΩ (R125) pull-up to `VCC3V3` |

`PHY_AD2`, `PHY_AD1`, `PHY_AD0` are low, low, high. This agrees with the MDIO address 1 of the
manual. `TXDLY` and `RXDLY` are both pulled up. The meaning of each strap value (for example,
whether high adds the RGMII clock delay) is in the RTL8211E datasheet, which is not in
`references/` (unknowns.md). The Linux device tree must agree with it (`phy-mode`).

## LEDs

**[schematic]** sheet 5: LAN1 has a yellow LED on `ACTLED0` (R110, 330 Ω, from `VCC3V3`) and a
two-color LED on `ACTLED2` and `ACTLED1` (R126, R127, 330 Ω). The LEDs CR6 and CR5 on the board
also show `ACTLED0` and `ACTLED1`. The manual gives the default behavior of the jack LEDs: the green
LED blinks with traffic, and the yellow LED blinks with activity and is off without a link.

## MAC address

The board has no EEPROM for a MAC address. The manual says that the OTP area of the QSPI flash
holds a unique EUI-48 identifier at OTP addresses 0x20 to 0x25, and that the PYNQ boot loader uses
it as the MAC address (boot.md). This was not read on the board.
