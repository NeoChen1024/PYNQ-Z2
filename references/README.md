# References

The documents of this directory are third-party material. They are here because their links on the
sites of AMD and TUL stopped working, or because the record cites them and a link can stop working. Each file is as it was downloaded; a new revision is a new
file. The documents of `docs/` cite these files and state their facts in their own words.

The rights stay with the publisher of each document. The MIT License of this repository does not
apply to them.

| File | Document | Publisher | SHA-256 |
|---|---|---|---|
| `tul/TUL_PYNQ_Schematic_R12.pdf` | PYNQ-Z2 schematic, 15 sheets. The file name says R12; the title blocks say R10, dated 2018-01-09 | TUL Corporation | `2a5c8bd73291901b80bed0d5b178def40e0ac7ca6ca0ea56f7acad1dd4f3c7c9` |
| `tul/pynqz2_user_manual_v1_0.pdf` | PYNQ-Z2 Reference Manual v1.0, 2018-05-17 | TUL Corporation | `47ebd0412126339cac0415a315f8878cb7dd7c138d406476cb4f928ca3c37404` |
| `tul/pynq-z2_v1.0.xdc` | Master XDC of the board, v1.0 (original name `PYNQ-Z2 v1.0.xdc`) | TUL Corporation | `70207ba33ed98e5a157999969350948b95d28ed471ab43fdc50975f60ffcc25b` |
| `tul/pynq-z2_v1.0_ps7_preset.tcl` | PS7 preset for the `processing_system7` IP, v1.0 (original name `PYNQ-Z2 v1.0.tcl`) | TUL Corporation | `1ebb6c4b332cb7f5f925488e6bce6aa2ce683469d0af7a4a34d6278cbbc6b6f2` |
| `amd/ds187-XC7Z010-XC7Z020-Data-Sheet.pdf` | DS187 v1.21 (2020-12-01), Zynq-7000 SoC DC and AC Switching Characteristics | Xilinx (AMD) | `61e245380c01d2b9cc1350d529265d185e04c1c0379b0fdb3adcba76585c8dac` |
| `amd/Zynq-7000_Xilinx_Wiki.pdf` | The Zynq-7000 pages of the Xilinx Wiki, exported 2024-01-04 | Xilinx (AMD) | `a4837b36df74949f389364c054d5e6533d815ed5cf610d0fd9dd51d07ef49453` |
| `micron/MT41K_DDR3L_4Gb_Rev.Q_Dec2017_DS.pdf` | 4Gb: x4, x8, x16 DDR3L SDRAM (MT41K1G4, MT41K512M8, MT41K256M16), data sheet Rev. Q 12/17, from micron.com | Micron Technology | `3b0a5ce422db7f8edaa2a44e389c03fc175b28a253acd2eed799016cbdd622e8` |
| `amd/ug585-Zynq-7000-TRM_v1.7.pdf` | UG585 v1.7 (2014-02-11), Zynq-7000 All Programmable SoC Technical Reference Manual (original name `ug585-Zynq-7000-TRM.pdf`) | Xilinx (AMD) | `79e7a6633896348138f2a37f4ed8004e41272d541aa7d6fdb72124409f0012d6` |
| `realtek/rtl8211e-vb-vl-cg_datasheet_1.6.pdf` | RTL8211E(G)-VB(VL)-CG data sheet Rev. 1.6 (2012-04-03) (original name `rtl8211e(g)-vb(vl)-cg_datasheet_1.6.pdf`) | Realtek Semiconductor | `b081006e6619ba24b38be4959675e36748ad3f80053f27e9319b38a44620fa3c` |
| `ti/tps65400_SLVSCQ9E.pdf` | TPS65400 data sheet SLVSCQ9E (revised 2022-03) (original name `tps65400.pdf`) | Texas Instruments | `a523c5007fd3f065a507fa90ba27b5fe26afa3af784894b81841e3f350f83efb` |
| `infineon/s25fl128s-s25fl256s_001-98283_RevT.pdf` | S25FL128S, S25FL256S data sheet 001-98283 Rev. *T (2025-04-21) (original name `infineon-s25fl128s-s25fl256s-128-mb-16-mb-256-mb-32-mb-fl-s-flash-spi-multi-io-3-v-datasheet-en.pdf`) | Infineon Technologies | `e8827e742d791a99e464ab8b694ff1354ef5322ca51b195d4e0f1afbec9457c4` |
| `adi/adau1761_RevF.pdf` | ADAU1761 data sheet Rev. F (2024-08) (original name `adau1761.pdf`) | Analog Devices | `3be39c360ad9f8aff432b7b1c7eebcb1985b2f5213f6b971fe4291c52d592024` |
| `zynq-book/The_Zynq_Book_ebook_3.pdf` | L. H. Crockett, R. A. Elliot, M. A. Enderwitz, R. W. Stewart: The Zynq Book, 1st edition, 2014 ([zynqbook.com](http://www.zynqbook.com/)) | Strathclyde Academic Media | `c565a4d7c41226a5a43161e2cb0da27c2d2a18a1bc6799dfd273655bc2eeb5cb` |
| `pinout/pinout.svg`, `pinout/pinout.png` | Pinout diagram of the board headers, by eneriz-daniel ([PYNQ forum](https://discuss.pynq.io/t/pynq-z2-pinout/4256/5)) | eneriz-daniel | svg `13d94bfca13524d88cf1eafa8eecc199d337d10a7c81fbc973e5d97bf094c965`, png `eb54515266215e0234b18f0b2eede0189d85dd9049babf8fc6d00854aa4e9b99` |

The product page of the board was
[amd.com: PYNQ-Z2](https://www.amd.com/en/corporate/university-program/aup-boards/pynq-z2.html).
The upstream of this collection is [ZeroX29a/PynqZ2](https://github.com/ZeroX29a/PynqZ2).

## Known faults

- `tul/pynq-z2_v1.0.xdc` does not have the pin V7 (Raspberry Pi GPIO27). Its port `a` collides with
  its bus `a[0..5]`. Ten of its comments give a wrong function name for the pin.
  `pynq_z2_master.xdc` corrects these points: see `tools/tables.py`.
- `tul/TUL_PYNQ_Schematic_R12.pdf` sheet 13 and `tul/pynqz2_user_manual_v1_0.pdf` give the DDR3
  part `MT41K512M16HA-125:A`. The board has `MT41K256M16TW-107:P`, by its marking (docs/ps.md).
