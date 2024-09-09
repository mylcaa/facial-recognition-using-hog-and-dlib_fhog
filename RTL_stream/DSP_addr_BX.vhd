library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DSP_addr_BX is
  Port (     
    clk: in std_logic;
    width_2: in std_logic_vector(8 downto 0);
    a: in std_logic_vector(5 downto 0); --i
    b: in std_logic_vector(5 downto 0); --cycle_num 
    c: in std_logic_vector(9 downto 0); --k
    d: in std_logic_vector(8 downto 0); --row_position
    const1: in std_logic_vector(1 downto 0);
    sel_addr: in std_logic;
    res: out std_logic_vector(9 downto 0) --bram addr
    );
end DSP_addr_BX;

architecture Behavioral of DSP_addr_BX is

attribute use_dsp : string;
attribute use_dsp of Behavioral : architecture is "yes";

signal mux_out1: std_logic_vector(5 downto 0);
signal mux_out2, reg_mux_out2: std_logic_vector(9 downto 0);

signal mult_out, reg_mult: std_logic_vector(14 downto 0);
signal adder_out: std_logic_vector(14 downto 0);

signal increment, reg_increment: std_logic_vector(9 downto 0);

begin
process(sel_addr, a, b, c, d)
begin

if(sel_addr = '0') then
    mux_out1 <= a;
    mux_out2 <= c;
else
    mux_out1 <= b;
    mux_out2 <= std_logic_vector(resize(unsigned(d),10));
end if;
end process;

increment <= std_logic_vector(resize(unsigned(const1),10) + unsigned(mux_out2));
mult_out <= std_logic_vector(unsigned(width_2) * unsigned(mux_out1));

--reg_middle: process(clk) is
--begin
--    if(rising_edge(clk)) then
--        reg_mult <= mult_out;
--        reg_increment <= increment;
--    end if;
--end process;

adder_out <= std_logic_vector(unsigned(mult_out) + resize(unsigned(increment),15));

--reg_out: process(clk) is
--begin
--    if(rising_edge(clk)) then
        res <= std_logic_vector(resize(unsigned(adder_out),10));
--    end if;
--end process;

end Behavioral;