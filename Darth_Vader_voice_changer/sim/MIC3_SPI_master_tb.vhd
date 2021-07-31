----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dominic Meads
-- 
-- Create Date: 07/26/2021 08:54:27 PM
-- Design Name: 
-- Module Name: MIC3_SPI_master_tb - sim
-- Project Name: Darth_Vader_voice_changer
-- Target Devices: 
-- Tool Versions: Vivado 2020.1
-- Description: Fetches 12-bit digital audio data from the PMOD MIC3, a MEMS microphone
--              connected to an ADC7476 (sampling @ ~44.1 KHz) DAC, using SPI.
--
--              NOTE: Actual sampling frequency is 44.01 KHz, which is as close
--                    I could get to 44.1 KHz without using a MMCM/PLL.
-- 
-- Dependencies: 100 MHz input clk
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Data sheet for ADC7476 found here:
--                      https://www.ti.com/lit/ds/symlink/adcs7476.pdf?_ga=2.119868360.1926354315.1627190855-336353978.1613715017
--                     
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MIC3_SPI_master_tb is
end MIC3_SPI_master_tb;

architecture sim of MIC3_SPI_master_tb is

  -- i_clk parameters
  constant clk_hz : integer := 100e6;  -- using the 100 MHz clk on the Arty board, not the 12 MHz clk.
  constant clk_period : time := 1 sec / clk_hz;

  -- DUT ports
  signal i_clk  : std_logic := '1';  -- input clk 100 MHz
  signal i_rst  : std_logic := '1';
  signal i_miso : std_logic := 'Z';  -- SDATA line of ADC7476
  signal o_sclk : std_logic;  
  signal o_cs   : std_logic;  
  signal o_dv   : std_logic;  -- output data valid
  signal o_data : std_logic_vector(11 downto 0); -- 12 bit word converted from SPI
  
  -- sclk edge counter
  signal r_sclk_cntr : integer range 0 to 16 := 0;
  
  -- 12 bit test sample from ADC
  signal sample : std_logic_vector(11 downto 0) := "110010100011";
  

begin

  DUT : entity work.MIC3_SPI_master(rtl)
  port map(
    i_clk => i_clk,
    i_rst => i_rst,
    i_miso => i_miso,
    o_sclk => o_sclk,
    o_cs => o_cs,
    o_dv => o_dv,
    o_data => o_data
    );
    
  CLK_GEN_PROC : process
  begin 
    wait for clk_period / 2;
    i_clk <= not i_clk;
  end process;
  
  SCLK_EDGE_CNTR_PROC : process
  begin 
    wait until falling_edge(o_sclk);
      if r_sclk_cntr < 16 then 
        r_sclk_cntr <= r_sclk_cntr + 1;
      else 
        r_sclk_cntr <= 0;
      end if;
  end process;
    
  STIM_PROC : process
  begin 
    wait for 10 us;
      i_rst <= '0';
    wait for 50 us;
      i_rst <= '1';
    wait for 10 us;
      i_rst <= '0';              -- verify proper reset with dummy conversion
    wait until r_sclk_cntr = 16; -- wait for dummy conversion to finish
    wait until o_cs = '1';       -- wait for DISABLE state
    wait for 100 ns;             -- wait minimum tquiet x 2 (pg 9 of datasheet)
    wait until o_cs = '0';       -- waits for master (FPGA) to tell ADC when to start conversion
    wait for 20 ns;              -- wait for t3 (time from CS falling edge to SDATA TRI-STATE DISABLE
      i_miso <= '0';             -- SDATA line now out of high-z
    wait until r_sclk_cntr = 4;  -- wait for 4th falling edge of sclk (leading zeros are clocked out on previous falling edges)
      i_miso <= sample(11);       -- output MSB of sample 
      
    wait;
  end process;

end sim;
