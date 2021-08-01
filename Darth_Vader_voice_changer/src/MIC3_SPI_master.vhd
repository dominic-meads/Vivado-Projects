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
  signal r_clk_cntr : integer range 0 to 141 := 0;
  signal r_clk_cntr_en : std_logic := '1';
  
  -- sclk edge counter
  signal r_sclk_cntr : integer range 0 to 16 := 0;
  
  -- FSM
  type t_state is (INIT_DUMMY, DISABLE, CONVERT);
  signal CURRENT_STATE : t_state := INIT_DUMMY;
  signal NEXT_STATE : t_state;
  
  -- input/output registers
  signal r_miso : std_logic := '0';
  signal r_cs : std_logic := '1';
  signal r_data : std_logic_vector(16 downto 0) := (others => '0');

begin

  -- counts the i_clk cycles to create a counter that wraps once every 1.42 us
  -- this will create an sclk frequency of 1/1.42 us or 704.225 KHz
  SCLK_GEN_PROC : process(i_clk) 
  begin 
    if rising_edge(i_clk) then 
      if i_rst = '1' then 
        r_clk_cntr <= 0;
      else
        if r_clk_cntr_en = '1' then
          if r_clk_cntr < 141 then 
            r_clk_cntr <= r_clk_cntr + 1;
          else 
            r_clk_cntr <= 0;
          end if;
        else 
          r_clk_cntr <= 0;
        end if;
      end if;
    end if;
  end process;
  
  -- controls state of sclk
  SCLK_OUTPUT_PROC : process(i_clk)
  begin
    if rising_edge(i_clk) then 
      if i_rst = '1' then 
        o_sclk <= '1';
      else 
        if r_cs = '1' then 
          o_sclk <= '1'; 
        else 
          if r_clk_cntr <= 70 then 
            o_sclk <= '1';
          else 
            o_sclk <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
      
  
  -- counts positive edges on sclk 
  SCLK_CNTR_PROC : process(i_clk)
  begin
    if rising_edge(i_clk) then 
      if i_rst = '1' then
        r_sclk_cntr <= 0;
      else 
        if r_clk_cntr = 141 then 
          if r_sclk_cntr < 16 then
            r_sclk_cntr <= r_sclk_cntr + 1;
          else 
            r_sclk_cntr <= 0;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -- FSM
  STATE_TRANSITION_PROC : process(r_sclk_cntr, r_clk_cntr)
  begin
    case CURRENT_STATE is 
      when INIT_DUMMY =>  -- after power on or post-shutdown mode, the ADC must initialize for 1 us or a single "dummy" conversion
        if r_sclk_cntr = 16 then 
          NEXT_STATE <= DISABLE;
        else 
          NEXT_STATE <= CURRENT_STATE;
        end if;
        
      when DISABLE =>  -- r_cs is high at this time, disabling the ADC for a minimum of 50 ns
        if r_clk_cntr = 6 then  -- enable and monitor r_clk_cntr for 6 counts or 60 ns, then move to CONVERT state
          NEXT_STATE <= CONVERT;
        else 
          NEXT_STATE <= CURRENT_STATE;
        end if; 
        
      when CONVERT => 
        if (r_sclk_cntr = 16 and r_clk_cntr > 6) then 
          NEXT_STATE <= DISABLE;
        else 
          NEXT_STATE <= CURRENT_STATE;
        end if;
        
      when others => 
        NEXT_STATE <= CURRENT_STATE;
    end case;
  end process;
  
  STATE_RST_PROC : process(i_clk)
  begin 
    if rising_edge(i_clk) then 
      if i_rst = '1' then 
        CURRENT_STATE <= INIT_DUMMY;
      else 
        CURRENT_STATE <= NEXT_STATE;
      end if;
    end if;
  end process;
  
  STATE_DEFINE_PROC : process(i_clk)
  begin 
    if rising_edge(i_clk) then 
      if i_rst = '1' then 
        r_cs <= '1';          -- bring CS high to disable ADC
        r_clk_cntr_en <= '0'; -- disable/reset counters
      else
        r_clk_cntr_en <= '1';
        case NEXT_STATE is 
          when INIT_DUMMY => 
            r_cs <= '0'; 
          when DISABLE =>
            r_cs <= '1';
          when CONVERT => 
            r_cs <= '0';
        end case;
      end if;
    end if;
  end process;

  o_cs <= r_cs;
  
  -- samples each bit on miso line
  SAMPLE_PROC : process(i_clk)
  begin 
    if rising_edge(i_clk) then 
      if i_rst = '1' or r_cs = '1' then 
        r_data <= (others => '0');
        o_dv <= '0';
      else
        r_miso <= i_miso;  -- register input data
        case r_sclk_cntr is 
          when 0  => r_data(16) <= r_miso;
          when 1  => r_data(15) <= r_miso;
          when 2  => r_data(14) <= r_miso;          
          when 3  => r_data(13) <= r_miso;          
          when 4  => r_data(12) <= r_miso;
          when 5  => r_data(11) <= r_miso;
          when 6  => r_data(10) <= r_miso;
          when 7  => r_data(9)  <= r_miso;
          when 8  => r_data(8)  <= r_miso;
          when 9  => r_data(7)  <= r_miso;
          when 10 => r_data(6)  <= r_miso;
          when 11 => r_data(5)  <= r_miso;
          when 12 => r_data(4)  <= r_miso;
          when 13 => r_data(3)  <= r_miso;
          when 14 => r_data(2)  <= r_miso;
          when 15 => r_data(1)  <= r_miso;
          when 16 => r_data(0)  <= '0';
        end case;
      end if;
    end if;
  end process;
  
  o_data <= r_data(12 downto 1);  -- omit leading zeros
  
  -- enable o_dv after the 16th positive edge and before disable state
  o_dv <= '1' when (r_sclk_cntr = 16 and r_cs = '0') else '0';  

end rtl;
