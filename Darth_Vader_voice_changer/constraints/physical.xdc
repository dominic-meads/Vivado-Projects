# Physical Constraints for Arty S7-25 board from Digilent

## 12 MHz input clk
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { i_clk }]; #IO_L13P_T2_MRCC_15 Sch=uclk

## 100 MHz input clk
set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { i_clk }]; #IO_L12P_T1_MRCC_34 Sch=ddr3_clk[200]

## MIC3 pins on Pmod Header JA
set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS33 } [get_ports { o_SS }]; #IO_L7P_T1_D09_14 Sch=ja_p[3] PIN 7
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { i_MISO }]; #IO_L8P_T1_D11_14 Sch=ja_p[4] PIN 9
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { o_SCLK }]; #IO_L8N_T1_D12_14 Sch=ja_n[4] PIN 10

## I2S2 pins on Pmod Header JD 
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { o_DAC_MCLK }]; #IO_L20N_T3_A07_D23_14 Sch=jd1/ck_io[33] PIN 1
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { o_DAC_LRCLK }]; #IO_L21P_T3_DQS_14 Sch=jd2/ck_io[32] PIN 2
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { o_DAC_SCLK }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=jd3/ck_io[31] PIN 3
set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { o_DAC_SDIN }]; #IO_L22P_T3_A05_D21_14 Sch=jd4/ck_io[30] PIN 4
