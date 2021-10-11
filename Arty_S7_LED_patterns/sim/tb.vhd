----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dominic Meads
-- 
-- Create Date: 10/10/2021 16:31:18 PM
-- Design Name: 
-- Module Name: LED_patterns - sim
-- Project Name: LED_patterns
-- Target Devices: 7 Series 
-- Tool Versions: 
-- Description: Implements a few different light patterns on the LEDs of a 
--              Digilent Arty S7 FPGA board. Each pattern is displayed for 
--              three seconds. 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity LED_patterns_tb is 
end LED_patterns_tb;

architecture sim of LED_patterns_tb is 

  constant clk_hz : integer := 12e6;
  constant clk_period : time := 1 sec / clk_hz;
  
  -- DUT signals 
  signal i_clk  : std_logic := '0';  
  signal o_LEDs : std_logic_vector(3 downto 0);

begin

  DUT : entity work.LED_patterns(rtl)
  port map (
    i_clk => i_clk,
    o_LEDs => o_LEDs
  );

  CLK_PROC : process
  begin 
    wait for clk_period / 2;
    i_clk <= not i_clk;
  end process;
  
  STIM_PROC : process 
  begin 
    wait for 10 sec;
    wait;
  end process;

end architecture;
