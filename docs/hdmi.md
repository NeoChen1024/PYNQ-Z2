# HDMI

The board has two HDMI type A receptacles: `HDMI_IN` (the sink) and `HDMI_OUT` (the source)
**[schematic] sheet 6**. **There is no HDMI transmitter or receiver chip.** The TMDS pairs go
directly to PL pins in banks 34 and 35 at 3.3 V. The design must do the TMDS coding itself
(for example with `OSERDESE2` and `ISERDESE2`). Each port can also be used in the other direction
**[manual]**, but the terminations of the board differ between the two ports (see below).

## Pins

| Signal | `HDMI_IN` pin | `HDMI_IN` port | `HDMI_OUT` pin | `HDMI_OUT` port |
|---|---|---|---|---|
| Clock P, N | N18, P19 | `hdmi_rx_clk_p`, `hdmi_rx_clk_n` | L16, L17 | `hdmi_tx_clk_p`, `hdmi_tx_clk_n` |
| Data 0 P, N | V20, W20 | `hdmi_rx_d_p[0]`, `hdmi_rx_d_n[0]` | K17, K18 | `hdmi_tx_d_p[0]`, `hdmi_tx_d_n[0]` |
| Data 1 P, N | T20, U20 | `hdmi_rx_d_p[1]`, `hdmi_rx_d_n[1]` | K19, J19 | `hdmi_tx_d_p[1]`, `hdmi_tx_d_n[1]` |
| Data 2 P, N | N20, P20 | `hdmi_rx_d_p[2]`, `hdmi_rx_d_n[2]` | J18, H18 | `hdmi_tx_d_p[2]`, `hdmi_tx_d_n[2]` |
| HPD | T19 (output) | `hdmi_rx_hpd` | R19 (input, inverted) | `hdmi_tx_hpdn` |
| CEC | H17 | `hdmi_rx_cec` | G15 | `hdmi_tx_cec` |
| DDC SCL | U14 | `hdmi_rx_scl` | MIO50 (B13) | PS |
| DDC SDA | U15 | `hdmi_rx_sda` | MIO51 (B9) | PS |

`HDMI_IN` is in bank 34; `HDMI_OUT` is in bank 35, except R19 in bank 34. The TMDS ports use
`TMDS_33` **[schematic] sheets 6, 10, 11**. The clock input N18 is on an MRCC pin.

**The DDC of `HDMI_OUT` goes to the PS, not to the PL**: `HDMI_TX_SCL` is MIO50 and `HDMI_TX_SDA` is
MIO51, in bank 501 at 1.8 V **[schematic] sheets 6, 10** **[manual]**. A design that reads the EDID
of a monitor uses a PS I2C controller (or PS GPIO) on these MIO pins. The PL cannot reach an MIO
pin. See [ps.md](ps.md).

## `HDMI_IN` (sink)

**[schematic] sheets 6, 11**:

- **TMDS termination.** R321 to R328 (49.9 ohm) pull each of the eight lines up to `VCC3V3`, near
  the FPGA (sheet 11). Sheet 6 also has 150 ohm pull-ups R139 to R146, marked `/X`. A photo of
  the board (2026-11-24) shows eight empty two-pad footprints beside the signal pins of the
  `HDMI_IN` connector. The silkscreen gives no part names, so that these are R139 to R146 is
  probable, not certain.
- **5 V.** Pin 18 of the connector is `HDMI_RX_5V0`, which the source supplies. Only the HPD buffer
  and the DDC level translator use it. It does not feed the board.
- **HPD.** The PL drives `HDMI_RX_HPD` (T19). Q7, a `NC7SZ125M5X` buffer on `HDMI_RX_5V0`, drives pin
  19 through R138 (1 kohm). Thus HPD can go high only while a source supplies 5 V. The output
  enable (Q7.1) goes to ground through R299, which is marked `/X`. Whether R299 is fitted is not
  known, but the HPD works **[measured]**: on 2026-11-24, an HDMI source (a PC graphics card) on
  `HDMI_IN` read the DDC within 1 s after each change of T19, five times; without a change of T19,
  the DDC stayed quiet for 20 s (`tools/pinprobe/`, `watch` with `hpd0`/`hpd1`). The source then
  reported no display, because no EDID answered. Because the HPD worked in each test, the owner
  thinks that R299 is fitted and that its `/X` is a mistake. The part was not seen.
- **DDC.** U7, a `GTL2002` level translator (marking `NXP_GTL2002GM`), connects `HDMI_RX_SCL` and
  `HDMI_RX_SDA` to pins 15 and 16. R150 and R151 (1 kohm) pull up the PL side to `VCC3V3`. R148 and
  R149 (1.5 kohm) pull up the connector side to `HDMI_RX_5V0`. The PL must answer as the EDID
  memory (I2C slave) if the source reads an EDID.
- **CEC.** Pin 13 has a pull-up of 27 kohm (R136) to `VCC3V3`. The Schottky diode D1 (`SS14-L`)
  connects it to H17, with the cathode on the PL side. Thus the PL can pull the line low. While
  the line is low, the diode blocks and the PL pin floats. Thus a PL input needs a pull-down to read
  the line. This follows from the schematic; it was not measured.

## `HDMI_OUT` (source)

**[schematic] sheet 6**:

- **TMDS.** R162 to R169 (49.9 ohm) pull each of the eight lines up to `VCC3V3`.
- **5 V.** `VCC5V0` goes through D3 (`SS14-L`) and the resettable fuse PS1 (`SMD1812P110TF`, 1.1 A)
  to pin 18 (`HDMI_TX_5V0`). The manual gives 50 mA for this pin **[manual]**. Q20, a second path
  from `VCC5V0`, is marked `/X`.
- **HPD.** Pin 19 goes through R160 (10 kohm) to the gate of Q8 (`2N7002-L`). R161 (10 kohm) holds
  the gate at ground. The drain is `HDMI_TX_HPDN` (R19), with R158 (4.7 kohm) to `VCC3V3`. Thus
  **R19 is low while a sink asserts HPD**, and high without a sink. The board file calls this pin
  `hdmi_tx_hpd` and does not show the inversion.
- **DDC.** U8, a second `GTL2002`, connects MIO50 and MIO51 to pins 15 and 16. R153 and R154 (1
  kohm) pull up the PS side to `VCC1V8`. R156 and R157 (1.5 kohm) pull up the connector side to
  `HDMI_TX_5V0`.
- **CEC.** The same circuit as `HDMI_IN`, with R159 (27 kohm) and D2 (`SS14-L`), on G15.

The shields of both connectors go to ground through 0 ohm (R147, R170). The schematic shows no ESD
part on the HDMI lines.

## Board file

The board file has the interfaces `hdmi_in`, `hdmi_in_ddc`, `hdmi_in_hpd_led`, `hdmi_out`,
`hdmi_out_cec` and `hdmi_out_hpd_led`, on the same pins as the table. It gives the `HDMI_OUT` TMDS
pins as `LVCMOS33` and the `HDMI_IN` TMDS pins as `TMDS_33`. It has no pin for `HDMI_RX_CEC` (H17).
The TUL XDC gives `TMDS_33` on all sixteen TMDS pins.
