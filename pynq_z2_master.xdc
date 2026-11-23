## Master XDC for the TUL PYNQ-Z2 (XC7Z020-1CLG400C). Made by tools/tables.py: do not edit by hand.
##
## Remove the comment mark from the ports that the design uses, and rename them to the top-level
## ports. The port names are those of the TUL XDC, with the corrections in tools/tables.py.
## The pins and nets come from the TUL schematic R12, and each pin function was checked against the
## package data of Vivado. pins.csv has the same data, pin by pin.
## The PS pins (MIO, DDR) are not here: the PS7 configuration sets them (docs/ps.md).

## Bank 0 is at 3.3 V (schematic sheet 12).
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock signal 125 MHz
#set_property -dict { PACKAGE_PIN H16  IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; # SYSCLK IO_L13P_T2_MRCC_35;  125 MHz from CLK125 of the Ethernet PHY U5; it stops while MIO9 (PHYRSTB) holds the PHY in reset (docs/clocks.md)
#create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## Switches
#set_property -dict { PACKAGE_PIN M20  IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]; # SW0 IO_L7N_T1_AD2N_35
#set_property -dict { PACKAGE_PIN M19  IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]; # SW1 IO_L7P_T1_AD2P_35

## RGB LEDs
#set_property -dict { PACKAGE_PIN L15  IOSTANDARD LVCMOS33 } [get_ports { led4_b }]; # LED4_B IO_L22N_T3_AD7N_35
#set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports { led4_g }]; # LED4_G IO_L16P_T2_35
#set_property -dict { PACKAGE_PIN N15  IOSTANDARD LVCMOS33 } [get_ports { led4_r }]; # LED4_R IO_L21P_T3_DQS_AD14P_35
#set_property -dict { PACKAGE_PIN G14  IOSTANDARD LVCMOS33 } [get_ports { led5_b }]; # LED5_B IO_0_35
#set_property -dict { PACKAGE_PIN L14  IOSTANDARD LVCMOS33 } [get_ports { led5_g }]; # LED5_G IO_L22P_T3_AD7P_35
#set_property -dict { PACKAGE_PIN M15  IOSTANDARD LVCMOS33 } [get_ports { led5_r }]; # LED5_R IO_L23N_T3_35

## LEDs
#set_property -dict { PACKAGE_PIN R14  IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; # LED0 IO_L6N_T0_VREF_34
#set_property -dict { PACKAGE_PIN P14  IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; # LED1 IO_L6P_T0_34
#set_property -dict { PACKAGE_PIN N16  IOSTANDARD LVCMOS33 } [get_ports { led[2] }]; # LED2 IO_L21N_T3_DQS_AD14N_35
#set_property -dict { PACKAGE_PIN M14  IOSTANDARD LVCMOS33 } [get_ports { led[3] }]; # LED3 IO_L23P_T3_35

## Buttons
#set_property -dict { PACKAGE_PIN D19  IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]; # BTN0 IO_L4P_T0_35
#set_property -dict { PACKAGE_PIN D20  IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]; # BTN1 IO_L4N_T0_35
#set_property -dict { PACKAGE_PIN L20  IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]; # BTN2 IO_L9N_T1_DQS_AD3N_35
#set_property -dict { PACKAGE_PIN L19  IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]; # BTN3 IO_L9P_T1_DQS_AD3P_35

## PmodA
#set_property -dict { PACKAGE_PIN Y18  IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]; # JA1_P IO_L17P_T2_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y19  IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]; # JA1_N IO_L17N_T2_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y16  IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]; # JA2_P IO_L7P_T1_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y17  IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]; # JA2_N IO_L7N_T1_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]; # JA3_P IO_L12P_T1_MRCC_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]; # JA3_N IO_L12N_T1_MRCC_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]; # JA4_P IO_L22P_T3_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]; # JA4_N IO_L22N_T3_34;  shared by PmodA and the Raspberry Pi header

## PmodB
#set_property -dict { PACKAGE_PIN W14  IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]; # JB1_P IO_L8P_T1_34
#set_property -dict { PACKAGE_PIN Y14  IOSTANDARD LVCMOS33 } [get_ports { jb[1] }]; # JB1_N IO_L8N_T1_34
#set_property -dict { PACKAGE_PIN T11  IOSTANDARD LVCMOS33 } [get_ports { jb[2] }]; # JB2_P IO_L1P_T0_34
#set_property -dict { PACKAGE_PIN T10  IOSTANDARD LVCMOS33 } [get_ports { jb[3] }]; # JB2_N IO_L1N_T0_34
#set_property -dict { PACKAGE_PIN V16  IOSTANDARD LVCMOS33 } [get_ports { jb[4] }]; # JB3_P IO_L18P_T2_34
#set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports { jb[5] }]; # JB3_N IO_L18N_T2_34
#set_property -dict { PACKAGE_PIN V12  IOSTANDARD LVCMOS33 } [get_ports { jb[6] }]; # JB4_P IO_L4P_T0_34
#set_property -dict { PACKAGE_PIN W13  IOSTANDARD LVCMOS33 } [get_ports { jb[7] }]; # JB4_N IO_L4N_T0_34

## Audio
#set_property -dict { PACKAGE_PIN M17  IOSTANDARD LVCMOS33 } [get_ports { adr0 }]; # ADR0 IO_L8P_T1_AD10P_35
#set_property -dict { PACKAGE_PIN M18  IOSTANDARD LVCMOS33 } [get_ports { adr1 }]; # ADR1 IO_L8N_T1_AD10N_35
#set_property -dict { PACKAGE_PIN R18  IOSTANDARD LVCMOS33 } [get_ports { au_bclk_r }]; # AU_BCLK_R IO_L20N_T3_34
#set_property -dict { PACKAGE_PIN G18  IOSTANDARD LVCMOS33 } [get_ports { au_din_r }]; # AU_DIN_R IO_L16N_T2_35
#set_property -dict { PACKAGE_PIN F17  IOSTANDARD LVCMOS33 } [get_ports { au_dout_r }]; # AU_DOUT_R IO_L6N_T0_VREF_35
#set_property -dict { PACKAGE_PIN U5   IOSTANDARD LVCMOS33 } [get_ports { au_mclk_r }]; # AU_MCLK_R IO_L19N_T3_VREF_13
#set_property -dict { PACKAGE_PIN U9   IOSTANDARD LVCMOS33 } [get_ports { au_scl_r }]; # AU_SCL_R IO_L17P_T2_13
#set_property -dict { PACKAGE_PIN T9   IOSTANDARD LVCMOS33 } [get_ports { au_sda_r }]; # AU_SDA_R IO_L12P_T1_MRCC_13
#set_property -dict { PACKAGE_PIN T17  IOSTANDARD LVCMOS33 } [get_ports { au_wclk_r }]; # AU_WCLK_R IO_L20P_T3_34

## Single Ended Analog Inputs
#set_property -dict { PACKAGE_PIN D18  IOSTANDARD LVCMOS33 } [get_ports { ar_an0_n }]; # AR_AN0_N IO_L3N_T0_DQS_AD1N_35
#set_property -dict { PACKAGE_PIN E17  IOSTANDARD LVCMOS33 } [get_ports { ar_an0_p }]; # AR_AN0_P IO_L3P_T0_DQS_AD1P_35
#set_property -dict { PACKAGE_PIN E19  IOSTANDARD LVCMOS33 } [get_ports { ar_an1_n }]; # AR_AN1_N IO_L5N_T0_AD9N_35
#set_property -dict { PACKAGE_PIN E18  IOSTANDARD LVCMOS33 } [get_ports { ar_an1_p }]; # AR_AN1_P IO_L5P_T0_AD9P_35
#set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS33 } [get_ports { ar_an2_n }]; # AR_AN2_N IO_L20N_T3_AD6N_35
#set_property -dict { PACKAGE_PIN K14  IOSTANDARD LVCMOS33 } [get_ports { ar_an2_p }]; # AR_AN2_P IO_L20P_T3_AD6P_35
#set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS33 } [get_ports { ar_an3_n }]; # AR_AN3_N IO_L24N_T3_AD15N_35
#set_property -dict { PACKAGE_PIN K16  IOSTANDARD LVCMOS33 } [get_ports { ar_an3_p }]; # AR_AN3_P IO_L24P_T3_AD15P_35
#set_property -dict { PACKAGE_PIN H20  IOSTANDARD LVCMOS33 } [get_ports { ar_an4_n }]; # AR_AN4_N IO_L17N_T2_AD5N_35
#set_property -dict { PACKAGE_PIN J20  IOSTANDARD LVCMOS33 } [get_ports { ar_an4_p }]; # AR_AN4_P IO_L17P_T2_AD5P_35
#set_property -dict { PACKAGE_PIN G20  IOSTANDARD LVCMOS33 } [get_ports { ar_an5_n }]; # AR_AN5_N IO_L18N_T2_AD13N_35
#set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVCMOS33 } [get_ports { ar_an5_p }]; # AR_AN5_P IO_L18P_T2_AD13P_35

## Arduino Digital I/O
#set_property -dict { PACKAGE_PIN T14  IOSTANDARD LVCMOS33 } [get_ports { ar[0] }]; # AR_IO0 IO_L5P_T0_34
#set_property -dict { PACKAGE_PIN U12  IOSTANDARD LVCMOS33 } [get_ports { ar[1] }]; # AR_IO1 IO_L2N_T0_34
#set_property -dict { PACKAGE_PIN U13  IOSTANDARD LVCMOS33 } [get_ports { ar[2] }]; # AR_IO2 IO_L3P_T0_DQS_PUDC_B_34;  also PUDC_B. The schematic shows no pull resistor, only 200 ohm to Arduino AR2
#set_property -dict { PACKAGE_PIN V13  IOSTANDARD LVCMOS33 } [get_ports { ar[3] }]; # AR_IO3 IO_L3N_T0_DQS_34
#set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports { ar[4] }]; # AR_IO4 IO_L10P_T1_34
#set_property -dict { PACKAGE_PIN T15  IOSTANDARD LVCMOS33 } [get_ports { ar[5] }]; # AR_IO5 IO_L5N_T0_34
#set_property -dict { PACKAGE_PIN R16  IOSTANDARD LVCMOS33 } [get_ports { ar[6] }]; # AR_IO6 IO_L19P_T3_34
#set_property -dict { PACKAGE_PIN U17  IOSTANDARD LVCMOS33 } [get_ports { ar[7] }]; # AR_IO7 IO_L9N_T1_DQS_34
#set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports { ar[8] }]; # AR_IO8 IO_L21P_T3_DQS_34
#set_property -dict { PACKAGE_PIN V18  IOSTANDARD LVCMOS33 } [get_ports { ar[9] }]; # AR_IO9 IO_L21N_T3_DQS_34
#set_property -dict { PACKAGE_PIN T16  IOSTANDARD LVCMOS33 } [get_ports { ar[10] }]; # AR_IO10 IO_L9P_T1_DQS_34;  AR_IO10. The board file in XilinxBoardStore 2025.2 and master calls this pin spi_ss_i, its 2022.2 branch arduino_a0_a13_tri_i_10. The schematic agrees with 2022.2
#set_property -dict { PACKAGE_PIN R17  IOSTANDARD LVCMOS33 } [get_ports { ar[11] }]; # AR_IO11 IO_L19N_T3_VREF_34
#set_property -dict { PACKAGE_PIN P18  IOSTANDARD LVCMOS33 } [get_ports { ar[12] }]; # AR_IO12 IO_L23N_T3_34
#set_property -dict { PACKAGE_PIN N17  IOSTANDARD LVCMOS33 } [get_ports { ar[13] }]; # AR_IO13 IO_L23P_T3_34
#set_property -dict { PACKAGE_PIN Y13  IOSTANDARD LVCMOS33 } [get_ports { ar_aref }]; # AR_IOA IO_L20N_T3_13;  on the AREF position of the Arduino header J3. The TUL XDC calls the port a, which collides with the bus a[0..5]

## Arduino Digital I/O On Outer Analog Header
#set_property -dict { PACKAGE_PIN Y11  IOSTANDARD LVCMOS33 } [get_ports { a[0] }]; # AR_A0 IO_L18N_T2_13
#set_property -dict { PACKAGE_PIN Y12  IOSTANDARD LVCMOS33 } [get_ports { a[1] }]; # AR_A1 IO_L20P_T3_13
#set_property -dict { PACKAGE_PIN W11  IOSTANDARD LVCMOS33 } [get_ports { a[2] }]; # AR_A2 IO_L18P_T2_13
#set_property -dict { PACKAGE_PIN V11  IOSTANDARD LVCMOS33 } [get_ports { a[3] }]; # AR_A3 IO_L21P_T3_DQS_13
#set_property -dict { PACKAGE_PIN T5   IOSTANDARD LVCMOS33 } [get_ports { a[4] }]; # AR_A4 IO_L19P_T3_13
#set_property -dict { PACKAGE_PIN U10  IOSTANDARD LVCMOS33 } [get_ports { a[5] }]; # AR_A5 IO_L12N_T1_MRCC_13

## Arduino SPI
#set_property -dict { PACKAGE_PIN W15  IOSTANDARD LVCMOS33 } [get_ports { ck_miso }]; # AR_MISO IO_L10N_T1_34
#set_property -dict { PACKAGE_PIN T12  IOSTANDARD LVCMOS33 } [get_ports { ck_mosi }]; # AR_MOSI IO_L2P_T0_34
#set_property -dict { PACKAGE_PIN H15  IOSTANDARD LVCMOS33 } [get_ports { ck_sck }]; # AR_SCK IO_L19P_T3_35
#set_property -dict { PACKAGE_PIN F16  IOSTANDARD LVCMOS33 } [get_ports { ck_ss }]; # AR_SS IO_L6P_T0_35;  AR_SS. The board file in XilinxBoardStore 2025.2 and master calls this pin arduino_a0_a13_tri_i_10, its 2022.2 branch spi_ss_i. The schematic agrees with 2022.2

## Arduino I2C
#set_property -dict { PACKAGE_PIN P16  IOSTANDARD LVCMOS33 } [get_ports { ar_scl }]; # AR_SCL IO_L24N_T3_34;  on J3.9, the SDA position of an Arduino Uno R3. The schematic and the TUL XDC call it AR_SCL; the manual and the board file call it SDA. Not measured
#set_property -dict { PACKAGE_PIN P15  IOSTANDARD LVCMOS33 } [get_ports { ar_sda }]; # AR_SDA IO_L24P_T3_34;  on J3.10, the SCL position of an Arduino Uno R3. The schematic and the TUL XDC call it AR_SDA; the manual and the board file call it SCL. Not measured

## Raspberry Digital I/O
#set_property -dict { PACKAGE_PIN W18  IOSTANDARD LVCMOS33 } [get_ports { rpio_02_r }]; # JA4_P IO_L22P_T3_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN W19  IOSTANDARD LVCMOS33 } [get_ports { rpio_03_r }]; # JA4_N IO_L22N_T3_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y18  IOSTANDARD LVCMOS33 } [get_ports { rpio_04_r }]; # JA1_P IO_L17P_T2_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y19  IOSTANDARD LVCMOS33 } [get_ports { rpio_05_r }]; # JA1_N IO_L17N_T2_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports { rpio_06_r }]; # JA3_P IO_L12P_T1_MRCC_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN U19  IOSTANDARD LVCMOS33 } [get_ports { rpio_07_r }]; # JA3_N IO_L12N_T1_MRCC_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN F19  IOSTANDARD LVCMOS33 } [get_ports { rpio_08_r }]; # RP_IO16 IO_L15P_T2_DQS_AD12P_35
#set_property -dict { PACKAGE_PIN V10  IOSTANDARD LVCMOS33 } [get_ports { rpio_09_r }]; # RP_IO07 IO_L21N_T3_DQS_13
#set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports { rpio_10_r }]; # RP_IO06 IO_L15P_T2_DQS_13
#set_property -dict { PACKAGE_PIN W10  IOSTANDARD LVCMOS33 } [get_ports { rpio_11_r }]; # RP_IO08 IO_L16P_T2_13
#set_property -dict { PACKAGE_PIN B20  IOSTANDARD LVCMOS33 } [get_ports { rpio_12_r }]; # RP_IO19 IO_L1N_T0_AD0N_35
#set_property -dict { PACKAGE_PIN W8   IOSTANDARD LVCMOS33 } [get_ports { rpio_13_r }]; # RP_IO12 IO_L15N_T2_DQS_13
#set_property -dict { PACKAGE_PIN V6   IOSTANDARD LVCMOS33 } [get_ports { rpio_14_r }]; # RP_IO02 IO_L22P_T3_13
#set_property -dict { PACKAGE_PIN Y6   IOSTANDARD LVCMOS33 } [get_ports { rpio_15_r }]; # RP_IO10 IO_L13N_T2_MRCC_13
#set_property -dict { PACKAGE_PIN B19  IOSTANDARD LVCMOS33 } [get_ports { rpio_16_r }]; # RP_IO20 IO_L2P_T0_AD8P_35
#set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports { rpio_17_r }]; # RP_IO03 IO_L11P_T1_SRCC_13
#set_property -dict { PACKAGE_PIN C20  IOSTANDARD LVCMOS33 } [get_ports { rpio_18_r }]; # RP_IO18 IO_L1P_T0_AD0P_35
#set_property -dict { PACKAGE_PIN Y8   IOSTANDARD LVCMOS33 } [get_ports { rpio_19_r }]; # RP_IO13 IO_L14N_T2_SRCC_13
#set_property -dict { PACKAGE_PIN A20  IOSTANDARD LVCMOS33 } [get_ports { rpio_20_r }]; # RP_IO21 IO_L2N_T0_AD8N_35
#set_property -dict { PACKAGE_PIN Y9   IOSTANDARD LVCMOS33 } [get_ports { rpio_21_r }]; # RP_IO15 IO_L14P_T2_SRCC_13
#set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports { rpio_22_r }]; # RP_IO05 IO_L17N_T2_13
#set_property -dict { PACKAGE_PIN W6   IOSTANDARD LVCMOS33 } [get_ports { rpio_23_r }]; # RP_IO09 IO_L22N_T3_13
#set_property -dict { PACKAGE_PIN Y7   IOSTANDARD LVCMOS33 } [get_ports { rpio_24_r }]; # RP_IO11 IO_L13P_T2_MRCC_13
#set_property -dict { PACKAGE_PIN F20  IOSTANDARD LVCMOS33 } [get_ports { rpio_25_r }]; # RP_IO17 IO_L15N_T2_DQS_AD12N_35
#set_property -dict { PACKAGE_PIN W9   IOSTANDARD LVCMOS33 } [get_ports { rpio_26_r }]; # RP_IO14 IO_L16N_T2_13
#set_property -dict { PACKAGE_PIN V7   IOSTANDARD LVCMOS33 } [get_ports { rpio_27_r }]; # RP_IO04 IO_L11N_T1_SRCC_13;  RPi GPIO27 (header pin 13): not in the TUL XDC or the board file
#set_property -dict { PACKAGE_PIN Y17  IOSTANDARD LVCMOS33 } [get_ports { rpio_sc_r }]; # JA2_N IO_L7N_T1_34;  shared by PmodA and the Raspberry Pi header
#set_property -dict { PACKAGE_PIN Y16  IOSTANDARD LVCMOS33 } [get_ports { rpio_sd_r }]; # JA2_P IO_L7P_T1_34;  shared by PmodA and the Raspberry Pi header

## HDMI Rx
#set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }]; # HDMI_RX_CEC IO_L13N_T2_MRCC_35;  through the Schottky diode D1, cathode on the PL side: a read needs a pull-down
#set_property -dict { PACKAGE_PIN P19  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_clk_n }]; # HDMI_RX_CLK_N IO_L13N_T2_MRCC_34
#set_property -dict { PACKAGE_PIN N18  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_clk_p }]; # HDMI_RX_CLK_P IO_L13P_T2_MRCC_34
#set_property -dict { PACKAGE_PIN W20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_n[0] }]; # HDMI_RX_D0_N IO_L16N_T2_34
#set_property -dict { PACKAGE_PIN U20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_n[1] }]; # HDMI_RX_D1_N IO_L15N_T2_DQS_34
#set_property -dict { PACKAGE_PIN P20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_n[2] }]; # HDMI_RX_D2_N IO_L14N_T2_SRCC_34
#set_property -dict { PACKAGE_PIN V20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_p[0] }]; # HDMI_RX_D0_P IO_L16P_T2_34
#set_property -dict { PACKAGE_PIN T20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_p[1] }]; # HDMI_RX_D1_P IO_L15P_T2_DQS_34
#set_property -dict { PACKAGE_PIN N20  IOSTANDARD TMDS_33 } [get_ports { hdmi_rx_d_p[2] }]; # HDMI_RX_D2_P IO_L14P_T2_SRCC_34
#set_property -dict { PACKAGE_PIN T19  IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_hpd }]; # HDMI_RX_HPD IO_25_34;  drives HPD through the buffer Q7, which runs on HDMI_RX_5V0
#set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_scl }]; # HDMI_RX_SCL IO_L11P_T1_SRCC_34
#set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_sda }]; # HDMI_RX_SDA IO_L11N_T1_SRCC_34

## HDMI Tx
#set_property -dict { PACKAGE_PIN G15  IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }]; # HDMI_TX_CEC IO_L19N_T3_VREF_35;  through the Schottky diode D2, cathode on the PL side: a read needs a pull-down
#set_property -dict { PACKAGE_PIN L17  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_clk_n }]; # HDMI_TX_CLK_N IO_L11N_T1_SRCC_35
#set_property -dict { PACKAGE_PIN L16  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_clk_p }]; # HDMI_TX_CLK_P IO_L11P_T1_SRCC_35
#set_property -dict { PACKAGE_PIN K18  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_n[0] }]; # HDMI_TX_D0_N IO_L12N_T1_MRCC_35;  sheet 11 names this pin IO_L12P_T1_MRCC_35, the same as K17; the package data gives IO_L12N_T1_MRCC_35
#set_property -dict { PACKAGE_PIN J19  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_n[1] }]; # HDMI_TX_D1_N IO_L10N_T1_AD11N_35
#set_property -dict { PACKAGE_PIN H18  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_n[2] }]; # HDMI_TX_D2_N IO_L14N_T2_AD4N_SRCC_35
#set_property -dict { PACKAGE_PIN K17  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_p[0] }]; # HDMI_TX_D0_P IO_L12P_T1_MRCC_35
#set_property -dict { PACKAGE_PIN K19  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_p[1] }]; # HDMI_TX_D1_P IO_L10P_T1_AD11P_35
#set_property -dict { PACKAGE_PIN J18  IOSTANDARD TMDS_33 } [get_ports { hdmi_tx_d_p[2] }]; # HDMI_TX_D2_P IO_L14P_T2_AD4P_SRCC_35
#set_property -dict { PACKAGE_PIN R19  IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_hpdn }]; # HDMI_TX_HPDN IO_0_34;  inverted: low while a sink asserts HPD (Q8)

## Crypto SDA
#set_property -dict { PACKAGE_PIN J15  IOSTANDARD LVCMOS33 } [get_ports { crypto_sda }]; # CRYPTO_SDA IO_25_35
