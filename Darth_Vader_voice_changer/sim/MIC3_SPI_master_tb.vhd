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
 
  -- 12 bit test sample from ADC
  signal sample : std_logic_vector(11 downto 0) := "110010100011";
  
  signal sclk_edge_cntr : integer := 0;

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
    
  STIM_PROC : process
  begin 
    wait for 10 us;
      i_rst <= '0';
    wait for 50 us;
      i_rst <= '1';
    wait for 10 us;
      i_rst <= '0';                 -- verify proper reset with dummy conversion
    wait until o_cs = '1';          -- wait for DISABLE state after dummy conversion
    wait for 100 ns;                -- wait minimum tquiet x 2 (pg 9 of datasheet)
    wait until o_cs = '0';          -- waits for master (FPGA) to tell ADC when to start conversion
    wait for 20 ns;                 -- wait for t3 (time from CS falling edge to SDATA TRI-STATE DISABLE
      i_miso <= '0';                -- SDATA line now out of high-z
    wait until o_sclk = '0';          -- wait for 1st falling edge of sclk 
      i_miso <= '0';
      sclk_edge_cntr <= 1;
    wait until o_sclk = '0';          -- clock out 3rd leading zero 
      i_miso <= '0';
      sclk_edge_cntr <= 2;    
    wait until o_sclk = '0';          -- clock out 4th leading zero
      i_miso <= '0';
      sclk_edge_cntr <= 3;      
    wait until o_sclk = '0';          -- clock out MSB of sample on 4th falling edge 
      i_miso <= sample(11);
      sclk_edge_cntr <= 4;      
    wait until o_sclk = '0';          -- clock out subsequent samples on falling edges
      i_miso <= sample(10);
      sclk_edge_cntr <= 5;
    wait until o_sclk = '0';          
      i_miso <= sample(9);
      sclk_edge_cntr <= 6;
    wait until o_sclk = '0';          
      i_miso <= sample(8);
      sclk_edge_cntr <= 7;
    wait until o_sclk = '0';          
      i_miso <= sample(7);
      sclk_edge_cntr <= 8;
    wait until o_sclk = '0';          
      i_miso <= sample(6);
      sclk_edge_cntr <= 9;
    wait until o_sclk = '0';          
      i_miso <= sample(5);
      sclk_edge_cntr <= 10;
    wait until o_sclk = '0';          
      i_miso <= sample(4);
      sclk_edge_cntr <= 11;
    wait until o_sclk = '0';          
      i_miso <= sample(3);
      sclk_edge_cntr <= 12;
    wait until o_sclk = '0';          
      i_miso <= sample(2);
      sclk_edge_cntr <= 13;
    wait until o_sclk = '0';          
      i_miso <= sample(1);
      sclk_edge_cntr <= 14;
    wait until o_sclk = '0';          
      i_miso <= sample(0);
      sclk_edge_cntr <= 15;
    wait until o_sclk = '0';
      sclk_edge_cntr <= 16;
    wait for 6 ns;                  -- back to high-z min. 6 ns after 16th falling edge of sclk (t8 in datasheet)
      i_miso <= 'Z';
    wait until o_sclk <= '1';
      sclk_edge_cntr <= 0;
    --wait until o_dv = '1';
      
    
    wait;
    
  end process;

end sim;
