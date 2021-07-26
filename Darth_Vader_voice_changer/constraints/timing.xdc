# Timing Constraints for Arty S7-25 board from Digilent

create_clock -add -name sys_clk_pin -period 83.333 -waveform {0 41.667} [get_ports { i_clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000}  [get_ports { i_clk }];
