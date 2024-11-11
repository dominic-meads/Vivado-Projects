library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iir_biquad_df1 is 
  port (
    clk  : in std_logic;
    din  : in signed(15 downto 0);
    dout : out signed(15 downto 0)
  );
end iir_biquad_df1;

architecture rtl of iir_biquad_df1 is

  -- filter coefficients (multiplied floating point coefficients by 2^14)
  -- sos = {1.0000   -1.8057    1.0000    1.0000   -1.9459    0.9480}
  --         b0         b1        b2        a0        a1        a2
  --   g = 0.0102 
  signal a1_fixed : signed(15 downto 0) := "0111110010001001";  -- 31881
  signal a2_fixed : signed(15 downto 0) := "1100001101010101"; 
  signal b0_fixed : signed(15 downto 0) := "0000000010100111";    -- g * b0 * 2^14  (multiply denom coeffs by gain for DF1 [source 1])
  signal b1_fixed : signed(15 downto 0) := "1111111011010010";    -- g * b1 * 2^14 
  signal b2_fixed : signed(15 downto 0) := "0000000010100111";    -- g * b2 * 2^14

  -- input register
  signal r_x : signed(15 downto 0) := (others => '0');

  -- delay registers
  signal r_x_z1 : signed(15 downto 0) := (others => '0');
  signal r_x_z2 : signed(15 downto 0) := (others => '0');
  signal r_y_z1 : signed(15 downto 0) := (others => '0');
  signal r_y_z2 : signed(15 downto 0) := (others => '0');

  -- multiplication signals
  signal w_product_a1 : signed(31 downto 0); 
  signal w_product_a2 : signed(31 downto 0); 
  signal w_product_b0 : signed(31 downto 0);
  signal w_product_b1 : signed(31 downto 0); 
  signal w_product_b2 : signed(31 downto 0); 

  -- accumulator
  signal w_sum : signed(31 downto 0);

begin

    process(clk) is 
    begin 
      if rising_edge(clk) then 
        r_x <= din;
        r_x_z1 <= r_x;
        r_x_z2 <= r_x_z1;
        r_y_z1 <= resize(shift_right(w_sum, 14),16);  -- divide by the same 2^14 value the coefficients were multiplied by
        r_y_z2 <= r_y_z1;
      end if;
    end process;

    -- multiply
    w_product_a1 <= r_y_z1 * a1_fixed;
    w_product_a2 <= r_y_z2 * a2_fixed;
    w_product_b0 <= r_x * b0_fixed;
    w_product_b1 <= r_x_z1 * b1_fixed;
    w_product_b2 <= r_x_z2 * b2_fixed;

    -- accumulate
    w_sum <= w_product_b0 + w_product_b1 + w_product_b2 + w_product_a1 + w_product_a2;

    dout <= r_y_z1;

end rtl;

