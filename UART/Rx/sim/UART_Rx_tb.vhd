-- tests the UART_Rx entity
--
-- Uses previously written UART_Tx module to transmitt/serialize an ASCII character. The data is transfered over a wire to the uut (UART_Rx).
-- The receiver turns the serial data into an 8-bit vector containing the original transmitted data similar to a loopback. 
-- 
-- UART Settings:
-- 9600 Baud
-- 8 data bits
-- No parity
-- 1 stop bit
--
-- Ver 1.0 Dominic Meads 2/8/2025

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_Rx_tb is 
end entity;

architecture sim of UART_Rx_tb is 

  -- uut signals
  signal clk          : std_logic := '0'; -- 12 MHz board clock
  signal rst_n        : std_logic := '0';
  signal rx_en        : std_logic := '0'; -- rx enable signal
  signal rx_data      : std_logic_vector(7 downto 0); -- ascii data vector complete after receiving all bits
  signal rx_complete  : std_logic; -- rx complete flag

  -- inter-entity signals
  signal w_tx_to_rx : std_logic;  -- serial wire between entities 

  -- other component signals
  signal tx_en        : std_logic := '0'; -- Tx enable signal
  signal tx_data      : std_logic_vector(7 downto 0) := x"41"; -- ascii data vector to transmit (ASCII character 'A')
  signal tx_complete  : std_logic; -- TX complete flag

begin 

  uut : entity work.UART_Rx(rtl)
    port map(
      clk         => clk,
      rst_n       => rst_n,
      rx_en       => rx_en,
      rx_in       => w_tx_to_rx,
      rx_data     => rx_data,
      rx_complete => rx_complete
    );

  i_UART_Tx : entity work.UART_Tx(rtl)
    port map(
      clk         => clk,
      rst_n       => rst_n,
      tx_en       => tx_en,
      tx_data     => tx_data,
      tx_out      => w_tx_to_rx,
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
    rx_en <= '1'; -- enable UART lines
    tx_en <= '1';
    wait for 1.2 ms;
    rst_n <= '0'; -- test reset
    wait;
  end process STIM_PROC;

  RX_RESULT_PROC : process is 
  begin 
    wait until rx_complete = '1'; -- start bit
    if rx_data = tx_data then 
      report "TRANSMISSION SUCCESSFUL: RX DATA SAME AS TX DATA";
    else 
      report "TRANSMISSION FAILED";
    end if; 
    wait;
  end process RX_RESULT_PROC;

end architecture;
