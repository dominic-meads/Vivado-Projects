-- tests the UART_Tx entity
-- 
-- UART Settings:
-- 9600 Baud
-- 8 data bits
-- No parity
-- 1 stop bit
--
-- Ver 1.0 Dominic Meads 2/7/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Tx_tb is 
end entity;

architecture sim of UART_Tx_tb is 

  signal clk          : std_logic := '0'; -- 12 MHz board clock
  signal rst_n        : std_logic := '0';
  signal tx_en        : std_logic := '0'; -- Tx enable signal
  signal tx_data      : std_logic_vector(7 downto 0) := x"41"; -- ascii data vector to transmit (ASCII character 'A')
  signal tx_out       : std_logic; -- UART Tx output line
  signal tx_complete  : std_logic; -- TX complete flag

  -- result of transmission
  signal tx_result : std_logic_vector(7 downto 0);

begin 

  uut : entity work.UART_Tx(rtl)
    port map(
      clk         => clk,
      rst_n       => rst_n,
      tx_en       => tx_en,
      tx_data     => tx_data,
      tx_out      => tx_out,
      tx_complete => tx_complete
    );

  CLK_PROC : process is
  begin 
    wait for 41.67 ns;
    clk <= not clk;
  end process CLK_PROC;

  STIM_PROC : process is
  begin 
    wait for 50 ns;
    rst_n <= '1'; -- release reset
    wait for 50 ns;
    tx_en <= '1'; -- enable UART Tx
    wait for 1.2 ms;
    rst_n <= '0'; -- test reset
    wait;
  end process STIM_PROC;

  RX_RESULT_PROC : process is 
  begin 
    wait until tx_out = '0'; -- start bit
    report "Start bit received, transmission incoming.";
    wait for 156.25 us;  -- wait for 1.5 bit periods @ 9600 buad to sample tx_out line when in the middle of bit period
    tx_result(0) <= tx_out;
    wait for 104.167 us;
    tx_result(1) <= tx_out;
    wait for 104.167 us;
    tx_result(2) <= tx_out;
    wait for 104.167 us;
    tx_result(3) <= tx_out;
    wait for 104.167 us;
    tx_result(4) <= tx_out;
    wait for 104.167 us;
    tx_result(5) <= tx_out;
    wait for 104.167 us;
    tx_result(6) <= tx_out;
    wait for 104.167 us;
    tx_result(7) <= tx_out;
    wait for 104.167 us;
    if tx_out = '1' then 
      report "Stop bit received";
    else 
      report "ERROR: Stop bit NOT received";
    end if;
    wait until tx_complete = '1';
    report "Transmission sequence complete";
    if tx_data = tx_result then 
      report "TRANSMISSION SUCCESFULL";
    else 
      report "ERROR TRANSMISSION FAILED";
    end if;
    wait;
  end process RX_RESULT_PROC;

end architecture;
