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

**U14 is not fitted.** The owner saw its footprint empty on 2026-11-24. The schematic marks U14,
R208 and R209 with `/X`. The manual does not name the chip **[manual]**. Thus `crypto_sda` (J15)
connects only to the footprint, and to R209 if R209 is fitted. A design must not expect a device
on it.

The TUL XDC has the port `crypto_sda` (section "Crypto SDA"). The board file has no interface for
the chip.
