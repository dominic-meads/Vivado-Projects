-- UART Transmitter
--
-- Takes in 8 bit vector and transmits over UART when "tx_en" is high. 
-- Transmission is complete when "tx_complete" goes high
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

entity UART_Tx is 
  port (
    clk         : in std_logic;  -- 12 MHz clk
    rst_n       : in std_logic;
    tx_en       : in std_logic;
    tx_data     : in std_logic_vector(7 downto 0);
    tx_out      : out std_logic;
    tx_complete : out std_logic  -- transmit complete (all bits transmitted)
  );
end entity;

architecture rtl of UART_Tx is

  -- output registers
  signal r_tx_out      : std_logic := '1';  -- active high idle state for Tx line
  signal r_tx_complete : std_logic := '0'; 

  -- counter to count the clocks per bit rate (12 MHz / 9600 Baud)
  signal r_clk_counter : unsigned(10 downto 0) := (others => '0');

  -- enable signal for counter (wont count in idle state)
  signal r_clk_counter_en : std_logic := '1'; 

  -- states
  type t_state is (IDLE, START, TX_BIT_0, TX_BIT_1, TX_BIT_2, TX_BIT_3, TX_BIT_4, 
                    TX_BIT_5, TX_BIT_6, TX_BIT_7, STOP, TX_SUCCESS);

  -- state machine registers
  signal r_current_state : t_state := IDLE;
  signal r_next_state    : t_state := IDLE;

begin

  -- if the enable is high, counter counts up to 1250 then restarts. If enable is low, counter is 0
  CLK_CNT_PROC : process(clk, rst_n) is 
  begin
    if rising_edge(clk) then  
      if rst_n = '0' then 
        r_clk_counter <= (others => '0');
      else 
        if r_clk_counter_en = '1' then 
          if r_clk_counter <= 1248 then 
            r_clk_counter <= r_clk_counter + 1;
          else 
            r_clk_counter <= (others => '0');
          end if;
        else 
          r_clk_counter <= (others => '0');
        end if;
      end if;
    end if; 
  end process CLK_CNT_PROC;

  -- next state logic
  NEXT_STATE_PROC : process (r_current_state, rst_n, tx_en, r_clk_counter) is
  begin 
    case r_current_state is 
      when IDLE => 
        if rst_n = '1' and tx_en = '1' then  -- stay in idle state unless reset is not active AND transmit is enabled
          r_next_state <= START;
        else 
          r_next_state <= IDLE;
        end if;

      when START => 
        if r_clk_counter = 1249 then -- wait for an entire "clks per bit" period
          r_next_state <= TX_BIT_0;  -- firs data bit is LSB (little endian)
        else 
          r_next_state <= START;
        end if; 

      when TX_BIT_0 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_1; 
        else 
          r_next_state <= TX_BIT_0;
        end if;
      
      when TX_BIT_1 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_2; 
        else 
          r_next_state <= TX_BIT_1;
        end if;

      when TX_BIT_2 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_3; 
        else 
          r_next_state <= TX_BIT_2;
        end if;

      when TX_BIT_3 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_4; 
        else 
          r_next_state <= TX_BIT_3;
        end if;

      when TX_BIT_4 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_5; 
        else 
          r_next_state <= TX_BIT_4;
        end if;

      when TX_BIT_5 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_6; 
        else 
          r_next_state <= TX_BIT_5;
        end if;

      when TX_BIT_6 => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_BIT_7; 
        else 
          r_next_state <= TX_BIT_6;
        end if;

      when TX_BIT_7 => 
        if r_clk_counter = 1249 then
          r_next_state <= STOP; 
        else 
          r_next_state <= TX_BIT_7;
        end if;

      when STOP => 
        if r_clk_counter = 1249 then
          r_next_state <= TX_SUCCESS; 
        else 
          r_next_state <= STOP;
        end if; 
      
      when TX_SUCCESS =>  -- only stay in this state for one clk cycle
          r_next_state <= IDLE;

      when others => 
          r_next_state <= IDLE;
    end case;
  end process NEXT_STATE_PROC;

  -- state update logic
  STATE_UPDATE_PROC : process(clk, rst_n) is 
  begin
    if rising_edge(clk) then  
      if rst_n = '0' then 
        r_current_state <= IDLE;
      else 
        r_current_state <= r_next_state;
      end if;
    end if;
  end process STATE_UPDATE_PROC;

  -- output logic
  STATE_OUTPUT_LOGIC_PROC : process(r_current_state, tx_data) is
  begin
    if r_current_state = IDLE then 
      r_clk_counter_en <= '0';
      r_tx_out         <= '1';
      r_tx_complete    <= '0';

    elsif r_current_state = START then 
      r_clk_counter_en <= '1';  -- enable clk counter
      r_tx_out         <= '0';  -- start bit is a '0'
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_0 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(0);  -- start shipping out bits LSB first
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_1 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(1); 
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_2 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(2);  
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_3 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(3); 
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_4 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(4);  
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_5 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(5);  
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_6 then 
      r_clk_counter_en <= '1'; 
      r_tx_out         <= tx_data(6);  
      r_tx_complete    <= '0';

    elsif r_current_state = TX_BIT_7 then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= tx_data(7);  
      r_tx_complete    <= '0';

    elsif r_current_state = STOP then 
      r_clk_counter_en <= '1';  
      r_tx_out         <= '1';  
      r_tx_complete    <= '0';

    elsif r_current_state = TX_SUCCESS then
      r_clk_counter_en <= '0';  
      r_tx_out         <= '1';  
      r_tx_complete    <= '1';

    else 
      r_clk_counter_en <= '0';  
      r_tx_out         <= '1';  
      r_tx_complete    <= '0';

    end if;
  end process STATE_OUTPUT_LOGIC_PROC;

  -- output assignments
  tx_out      <= r_tx_out;
  tx_complete <= r_tx_complete;

end architecture;
