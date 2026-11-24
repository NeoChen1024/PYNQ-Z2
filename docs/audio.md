# Audio

The board has an Analog Devices ADAU1761 audio codec (AU1, marking `ADAU1761BCPZ`) **[schematic]
sheet 7**. The codec has no crystal. **The PL gives the master clock** on `AU_MCLK_R`.

## Pins

All signals go to PL pins at 3.3 V. The codec runs its I/O at 3.3 V too (IOVDD on `VCC3V3`)
**[schematic] sheets 7, 11, 12**.

| Net (PL side) | Codec pin | Direction | Pin | Bank | Port |
|---|---|---|---|---|---|
| `AU_MCLK_R` | MCLK (2) | PL to codec | U5 | 13 | `au_mclk_r` |
| `AU_BCLK_R` | BCLK/GPIO2 (28) | both, see below | R18 | 34 | `au_bclk_r` |
| `AU_WCLK_R` | LRCLK/GPIO3 (29) | both, see below | T17 | 34 | `au_wclk_r` |
| `AU_DIN_R` | DAC_SDATA/GPIO0 (27) | PL to codec | G18 | 35 | `au_din_r` |
| `AU_DOUT_R` | ADC_SDATA/GPIO1 (26) | codec to PL | F17 | 35 | `au_dout_r` |
| `AU_SCL_R` | SCL/CCLK (32) | PL to codec | U9 | 13 | `au_scl_r` |
| `AU_SDA_R` | SDA/COUT (31) | both | T9 | 13 | `au_sda_r` |
| `ADR0` | ADR0/CLATCH (3) | PL to codec | M17 | 35 | `adr0` |
| `ADR1` | ADR1/CDATA (30) | PL to codec | M18 | 35 | `adr1` |

The names `DIN` and `DOUT` are those of the codec: `AU_DIN_R` is the data to the DAC and `AU_DOUT_R`
is the data from the ADC. The board file names F17 `sdata_in_i` and G18 `sdada_out_i`, from the
side of the PL.

The codec can be master or slave of BCLK and LRCLK. The registers of the codec select this. The
board does not fix it.

The circuit, **[schematic] sheet 7**:

- Each signal goes through a 0 ohm resistor between the PL net (`AU_*_R`) and the codec. MCLK has a
  further 50 ohm (R80) at the codec.
- R297 and R298 (2.2 kohm) pull `AU_SDA` and `AU_SCL` up to `VCC3V3`. Thus the control bus is I2C.
- R301 and R312 (10 kohm) pull `ADR0` and `ADR1` up to `VCC3V3`. If the design does not drive the
  two pins, both address pins are high.
- R180 (2.2 kohm, marked `/X`) can pull `AU_MCLK_R` up. R180 is not fitted **[measured]**: U5
  followed the internal pull of the PL in both pinprobe builds (2026-11-24, `tools/pinprobe/`).

## Control port

The ADAU1761 data sheet (`references/adi/adau1761_RevF.pdf`) gives these facts:

- The control port starts in I2C mode. Three low pulses on CLATCH (`ADR0`) switch it to SPI mode,
  and only a power cycle brings it back (page 39). **A design must not toggle `ADR0`.**
- The 7-bit I2C address is 0x38 + 2 × ADR1 + ADR0 (Table 21, page 36). The subaddress has 16 bits.
  The bus runs at up to 400 kHz (page 10).
- Without the core clock, only R0 (0x4000) and R1 (0x4002) are accessible; all other registers
  need a valid MCLK and `COREN` (page 36, Table 35 on page 51).
- The PLL takes MCLK from 8 MHz to 27 MHz (page 24). The direct mode takes 256, 512, 768 or 1024
  times the sample rate (page 22).

On 2026-11-24, the I2C scan of `tools/pinprobe/` found the codec **[measured]**:

| ADR1 | ADR0 | Address that answered |
|---|---|---|
| High (pull-up) | High (pull-up) | 0x3B |
| Low (driven by the PL) | High (pull-up) | 0x39 |

The codec answered at 0x3B also without MCLK. The scan sent only the address of each device (0x08
to 0x77). No other device answered on the bus.

The schematic does not give a frequency for MCLK. The design chooses it, within the limits of the
ADAU1761 data sheet. The manual gives stereo 48 kHz, and sample rates from 8 kHz to 96 kHz
**[manual]**.

There is no reset pin. The revision history of the schematic (sheet 2) says that the net of V5
became `AU_RESET`. On sheet 11 of R12, V5 has no net. The ADAU1761 has no reset input in the
symbol of sheet 7. V5 is not connected on this board **[measured]**: it followed the internal pull
of the PL in both pinprobe builds (2026-11-24).

## Jacks

**[schematic] sheet 7**:

| Jack | Part | Signals |
|---|---|---|
| `CN_AUDIO1` ("MIC + HP") | `SJ-43515TS-SMT`, 4-contact (TRRS) 3.5 mm | Headphone left and right, microphone |
| `LINE_IN1` ("LINE_IN") | `JACK_6H` | Line input, left and right |

- **Headphone.** The outputs LHP and RHP drive `FR_L` and `FR_R`. They go through 100 µF capacitors
  and ferrite beads to the jack (`FRONT_L`, `FRONT_R`).
- **Microphone.** U41, a `TS3A226AEYFFR` (Texas Instruments, headset detection switch), connects the
  microphone contact of the jack (`RING2` or `SLEEVE`) to `MICP`. `MICP` goes through ferrite beads
  to `MIC1_L` and `MIC1_R`, which both get `MICBIAS` through 2.2 kohm (R303, R304). They go through
  10 µF to the inputs LINN and RINN of the codec. Thus left and right get the same microphone
  signal.
- **Line input.** `LINE1_L` and `LINE1_R` go through 1 kohm and 4700 pF (a low-pass filter) and
  10 µF to the inputs LAUX and RAUX.
- The line outputs (LOUTP, ROUTP) go only to the test points TP29 and TP30. MONOOUT goes to Q19,
  which is marked `/X`.

The manual calls the output a "24bit I2S DAC with 3.5mm TRRS jack" **[manual]**.

## Board file

The board file has the interfaces `audio_i2c`, `audio_i2s`, `audio_clock` and `audio_addr` on the
same pins as the table. The TUL XDC has the same pins and the port names of the table.
