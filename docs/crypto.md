# Crypto chip

The schematic shows U14, an `ATSHA204A-SSHCZ-T` (Microchip, authentication chip with SHA-256), on the
net `CRYPTO_SDA` **[schematic] sheet 9**.

| Signal | Pin | Bank | Port |
|---|---|---|---|
| `CRYPTO_SDA` | J15 | 35 (3.3 V) | `crypto_sda` |

The connections, **[schematic] sheet 9**:

- U14.8 (VCC) gets `VCC3V3` through R208 (4.7 kohm).
- U14.5 (SDA) is `CRYPTO_SDA`. R209 (1.2 kohm) pulls it up to the same 3.3 V.
- U14.6 (SCL) is not connected. U14.4 is ground. Pins 1 to 3 and 7 are not connected.

Only SDA reaches the FPGA. Thus the design must use the one-wire interface of the chip. The
ATSHA204A data sheet describes that interface. It is not in this repository.

**It is not known whether U14, R208 and R209 are fitted.** The schematic marks all three with `/X`.
The schematic does not define `/X`. Other parts with `/X` include R139 to R146, 150 ohm HDMI
pull-ups whose task R321 to R328 already do ([hdmi.md](hdmi.md)). This suggests that `/X` marks a
part that is not fitted, but no source says so. The manual does not name the chip **[manual]**. See
[unknowns.md](unknowns.md).

The TUL XDC has the port `crypto_sda` (section "Crypto SDA"). The board file has no interface for
the chip.
