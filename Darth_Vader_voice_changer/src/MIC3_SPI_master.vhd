----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Dominic Meads
-- 
-- Create Date: 07/25/2021 08:35:18 PM
-- Design Name: 
-- Module Name: MIC3_SPI_master - rtl
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MIC3_SPI_master is
  Port (
    i_clk  : in  std_logic;  -- input clk 100 MHz
    i_rst  : in  std_logic;
    i_miso : in  std_logic;  -- SDATA line of ADC7476
    o_sclk : out std_logic;  
    o_cs   : out std_logic;  
    o_dv   : out std_logic;  -- output data valid
    o_data : out std_logic_vector(11 downto 0) -- 12 bit word converted from SPI
  );
end MIC3_SPI_master;

architecture rtl of MIC3_SPI_master is

  -- counter to create sclk
  signal r_sclk_counter : integer range 0 to 139 := 0;
  
  -- FSM
  type t_state is (DUMMY, SAMPLE);
  signal STATE : t_state := DUMMY;

begin

  -- counts the i_clk cycles to create a counter that wraps once every 1.4 us
  -- this will create an sclk frequency of 1/1.4 us or 714.285 KHz
  SCLK_GEN_PROC : process(i_clk, i_rst) 
  begin 
    if rising_edge(i_clk) then 
      if i_rst = '1' then 
        r_sclk_counter <= 0;
      else 
        if r_sclk_counter < 139 then 
          r_sclk_counter <= r_sclk_counter + 1;
        else 
          r_sclk_counter <= 0;
        end if;
      end if;
    end if;
  end process;
  
  -- create 50% duty cycle on sclk
  o_sclk <= '1' when r_sclk_counter <= 69 else '0';
  
  

  


end rtl;
