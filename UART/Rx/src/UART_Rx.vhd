-- UART Reciever
--
-- Takes in serial data over UART and converts to paralell when "rx_en" is high. 
-- Receive is complete when "rx_complete" goes high
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

entity UART_Rx is 
  port (
    clk         : in std_logic;
    rst_n       : in std_logic;
    rx_en       : in std_logic;
    rx_in       : in std_logic;
    rx_data     : out std_logic_vector(7 downto 0);
    rx_complete : out std_logic
  );
end entity; 

architecture rtl of UART_Rx is
  
  -- output registers
  signal r_rx_data     : std_logic_vector(7 downto 0) := (others => '0');
  signal r_rx_complete : std_logic := '0';

  -- counter
  signal r_clk_counter : unsigned(10 downto 0) := (others => '0');

  -- enable signals (each allows counter to count to different value)
  -- example: first counter enable allows counter to go up to 1.5 times the clks per bit period (used to count PAST the stop bit and into the MIDDLE of the first bit from the RX wire)
  signal r_cntr_one_and_half_period_en : std_logic := '0'; 
  signal r_cntr_one_period_en          : std_logic := '0';
  signal r_cntr_half_period_en         : std_logic := '0';

  -- state types
  type t_state is (IDLE, START, RX_BIT_0, RX_BIT_1, RX_BIT_2, RX_BIT_3, RX_BIT_4, 
  RX_BIT_5, RX_BIT_6, RX_BIT_7, STOP, RX_SUCCESS);

  -- state registers
  signal r_current_state : t_state := IDLE;
  signal r_next_state    : t_state := IDLE;


begin

  CLK_COUNTER_PROC : process(clk, rst_n) is 
  begin
    if rising_edge(clk) then 
      if rst_n = '0' then 
        r_clk_counter <= (others => '0');
      else 
        if r_cntr_one_and_half_period_en = '1' and r_cntr_one_period_en = '0' and r_cntr_half_period_en = '0' then 
          if r_clk_counter <= 1873 then 
            r_clk_counter <= r_clk_counter + 1;
          else 
            r_clk_counter <= (others => '0');
          end if;
        elsif r_cntr_one_and_half_period_en = '0' and r_cntr_one_period_en = '1' and r_cntr_half_period_en = '0' then 
          if r_clk_counter <= 1248 then 
            r_clk_counter <= r_clk_counter + 1;
          else 
            r_clk_counter <= (others => '0');
          end if;
        elsif r_cntr_one_and_half_period_en = '0' and r_cntr_one_period_en = '0' and r_cntr_half_period_en = '1' then 
          if r_clk_counter <= 623 then 
            r_clk_counter <= r_clk_counter + 1;
          else 
            r_clk_counter <= (others => '0');
          end if;
        else  -- if multiple enables high or all enables low
          r_clk_counter <= (others => '0');
        end if;
      end if;
    end if; 
  end process CLK_COUNTER_PROC;

  -- next state logic
  NEXT_STATE_PROC : process (r_current_state, rst_n, rx_en, rx_in, r_clk_counter) is 
  begin
    case r_current_state is 
      when IDLE => 
        if rst_n = '1' and rx_en = '1' and rx_in = '0' then -- wait until Rx line goes low
          r_next_state <= START;
        else 
          r_next_state <= IDLE;
        end if;

      when START =>  
        if r_clk_counter = 1874 then 
          r_next_state <= RX_BIT_0;
        else 
          r_next_state <= START;
        end if;

      when RX_BIT_0 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_1; 
        else 
          r_next_state <= RX_BIT_0;
        end if;
      
      when RX_BIT_1 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_2; 
        else 
          r_next_state <= RX_BIT_1;
        end if;

      when RX_BIT_2 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_3; 
        else 
          r_next_state <= RX_BIT_2;
        end if;

      when RX_BIT_3 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_4; 
        else 
          r_next_state <= RX_BIT_3;
        end if;

      when RX_BIT_4 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_5; 
        else 
          r_next_state <= RX_BIT_4;
        end if;

      when RX_BIT_5 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_6; 
        else 
          r_next_state <= RX_BIT_5;
        end if;

      when RX_BIT_6 => 
        if r_clk_counter = 1249 then
          r_next_state <= RX_BIT_7; 
        else 
          r_next_state <= RX_BIT_6;
        end if;

      when RX_BIT_7 => 
        if r_clk_counter = 1249 then
          r_next_state <= STOP; 
        else 
          r_next_state <= RX_BIT_7;
        end if;

      when STOP => 
        if r_clk_counter = 624 then
          r_next_state <= RX_SUCCESS; 
        else 
          r_next_state <= STOP;
        end if; 
      
      when RX_SUCCESS =>  -- only stay in this state for one clk cycle
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
  STATE_OUTPUT_LOGIC_PROC : process(clk, r_current_state, rx_in, r_rx_data) is -- had to make this process sequential (had a latch for r_rx_data)
  begin
    if rising_edge(clk) then 
      if r_current_state = IDLE then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '0';
        r_cntr_half_period_en         <= '0';
        r_rx_data     <= (others => '0');
        r_rx_complete <= '0';

      elsif r_current_state = START then 
        r_cntr_one_and_half_period_en <= '1';
        r_cntr_one_period_en          <= '0';
        r_cntr_half_period_en         <= '0';
        r_rx_data     <= (others => '0');
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_0 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(0)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_1 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(1)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_2 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(2)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_3 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(3)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_4 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(4)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_5 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(5)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_6 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(6)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = RX_BIT_7 then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '1';
        r_cntr_half_period_en         <= '0';
        if r_clk_counter = 1 then 
          r_rx_data(7)  <= rx_in;
        end if;
        r_rx_complete <= '0';

      elsif r_current_state = STOP then 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '0';
        r_cntr_half_period_en         <= '1';
        r_rx_data     <= r_rx_data;
        r_rx_complete <= '0';

      elsif r_current_state = RX_SUCCESS then
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '0';
        r_cntr_half_period_en         <= '0';
        r_rx_data     <= r_rx_data;
        r_rx_complete <= '1';

      else 
        r_cntr_one_and_half_period_en <= '0';
        r_cntr_one_period_en          <= '0';
        r_cntr_half_period_en         <= '0';
        r_rx_data     <= (others => '0');
        r_rx_complete <= '0';
      end if;
    end if;
  end process STATE_OUTPUT_LOGIC_PROC;
  
  -- output assignments
  rx_data     <= r_rx_data;
  rx_complete <= r_rx_complete;

end architecture;
