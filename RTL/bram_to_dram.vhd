library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity bram_to_dram is
  Port ( 
    clk: in std_logic;
    reset: in std_logic;
    --reg bank
    width: in std_logic_vector(9 downto 0);
    width_4: in std_logic_vector(7 downto 0);
    width_2: in std_logic_vector(8 downto 0);
    height: in std_logic_vector(10 downto 0);
    bram_height: in std_logic_vector(4 downto 0);
    cycle_num_out: in std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
    dram_x_addr: in std_logic_vector(31 downto 0);
    dram_y_addr: in std_logic_vector(31 downto 0);
    burst_len_write: out std_logic_vector(7 downto 0);
    --sig for FSM
    en_bram_to_dram: in std_logic;
    bram_to_dram_finished: out std_logic;
    --bram_to_dram
    bram_addr_bram_to_dram_A: out std_logic_vector(9 downto 0);
    bram_addr_bram_to_dram_B: out std_logic_vector(9 downto 0);
    sel_dram: out std_logic_vector(4 downto 0);
    dram_out_addr_x: out std_logic_vector(31 downto 0);
    dram_out_addr_y: out std_logic_vector(31 downto 0));
end bram_to_dram;

architecture Behavioral of bram_to_dram is

--states bram_to_dram
type state_bram_to_dram_t is
    (init_loop_bram_to_dram, loop_bram_to_dram1);
signal state_bram_to_dram_r, state_bram_to_dram_n: state_bram_to_dram_t;

--reg bank
signal width_reg, width_next: std_logic_vector(9 downto 0);
signal width_2_reg, width_2_next: std_logic_vector(8 downto 0);
signal width_4_reg, width_4_next: std_logic_vector(7 downto 0);
signal height_reg, height_next: std_logic_vector(10 downto 0);
signal bram_height_reg, bram_height_next: std_logic_vector(4 downto 0);
signal cycle_num_out_reg, cycle_num_out_next: std_logic_vector(5 downto 0);
signal dram_x_addr_reg, dram_x_addr_next: std_logic_vector(31 downto 0); 
signal dram_y_addr_reg, dram_y_addr_next: std_logic_vector(31 downto 0);

signal y_reg, y_next: std_logic_vector(5 downto 0);
signal row_cnt_reg, row_cnt_next: std_logic_vector(10 downto 0); --provjeri
signal z_reg, z_next: std_logic_vector(8 downto 0);

signal sel_dram_reg, sel_dram_next: std_logic_vector(4 downto 0);
signal dram_out_addr_x_s, dram_out_addr_y_s: std_logic_vector(31 downto 0);
signal bram_addr_bram_to_dram_A_s: std_logic_vector(9 downto 0);
signal bram_addr_bram_to_dram_B_s: std_logic_vector(9 downto 0);
signal burst_len_write_s: std_logic_vector(7 downto 0);

signal bram_to_dram_finished_s: std_logic;

begin

--init
process(clk) 
begin

if(rising_edge(clk)) then
    if reset = '1' then
        state_bram_to_dram_r <= init_loop_bram_to_dram;
        
        sel_dram_reg <= (others => '0');

        y_reg <= (others => '0');
        row_cnt_reg <= (others => '0');
        z_reg <= (others => '0');
        
        burst_len_write_s <= "11111111";
    else
        state_bram_to_dram_r <= state_bram_to_dram_n;

        width_reg <= width_next;
        width_2_reg <= width_2_next;
        width_4_reg <= width_4_next;
        height_reg <= height_next;
        bram_height_reg <= bram_height_next;
        cycle_num_out_reg <= cycle_num_out_next;
        dram_x_addr_reg <= dram_x_addr_next;
        dram_y_addr_reg <= dram_y_addr_next;

        sel_dram_reg <= sel_dram_next;
        
        y_reg <= y_next;
        row_cnt_reg <= row_cnt_next;
        z_reg <= z_next;
        
        burst_len_write_s <= std_logic_vector(unsigned(width_4_reg) - 2);
    end if;
end if;
end process;


process(state_bram_to_dram_r, sel_dram_reg, y_reg, row_cnt_reg, z_reg, width, width_2, width_4, height, bram_height, cycle_num_out,
        dram_x_addr, dram_y_addr, en_bram_to_dram, width_reg, width_2_reg, width_4_reg, height_reg, bram_height_reg,
        cycle_num_out_reg, dram_x_addr_reg, dram_y_addr_reg, y_next, sel_dram_next) 
begin

state_bram_to_dram_n <= state_bram_to_dram_r;

sel_dram_next <= sel_dram_reg;
y_next <= y_reg;
row_cnt_next <= row_cnt_reg;
z_next <= z_reg;

width_next <= width_reg;
width_2_next <= width_2_reg;
width_4_next <= width_4_reg;
height_next <= height_reg;
bram_height_next <= bram_height_reg;
cycle_num_out_next <= cycle_num_out_reg;
dram_x_addr_next <= dram_x_addr_reg;
dram_y_addr_next <= dram_y_addr_reg;

case state_bram_to_dram_r is
    when init_loop_bram_to_dram =>
        width_next <= width;
        width_2_next <= width_2;
        width_4_next <= width_4;
        height_next <= height;
        bram_height_next <= bram_height;
        cycle_num_out_next <= cycle_num_out;
        dram_x_addr_next <= dram_x_addr;
        dram_y_addr_next <= dram_y_addr;
        
        if(en_bram_to_dram = '1') then
            y_next <= (others => '0');
            z_next <= (others => '0');
            sel_dram_next <= (others => '0');
            dram_out_addr_x_s <= std_logic_vector(unsigned(dram_x_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
            dram_out_addr_y_s <= std_logic_vector(unsigned(dram_y_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
            state_bram_to_dram_n <= loop_bram_to_dram1;
        end if;

    when loop_bram_to_dram1 =>
        bram_addr_bram_to_dram_A_s <= std_logic_vector(resize(unsigned(y_reg)*(unsigned(width_2_reg)-1)+unsigned(z_reg),10));
        bram_addr_bram_to_dram_B_s <= std_logic_vector(resize(unsigned(y_reg)*(unsigned(width_2_reg)-1)+unsigned(z_reg)+1,10));
        z_next <= std_logic_vector(unsigned(z_reg)+1);
        
        if(z_reg = std_logic_vector(unsigned(width_2_reg) - 1)) then
            row_cnt_next <= std_logic_vector(unsigned(row_cnt_reg)+1);
            sel_dram_next <= std_logic_vector(unsigned(sel_dram_reg)+1);
            if(sel_dram_next = bram_height_reg) then
                y_next <= std_logic_vector(unsigned(y_reg)+1);
                if(y_next = cycle_num_out_reg) then
                    bram_to_dram_finished_s <= '1';
                else
                    z_next <= (others => '0');
                    sel_dram_next <= (others => '0');
                    dram_out_addr_x_s <= std_logic_vector(unsigned(dram_x_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
                    dram_out_addr_y_s <= std_logic_vector(unsigned(dram_y_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
                end if;
            else
                dram_out_addr_x_s <= std_logic_vector(unsigned(dram_x_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
                dram_out_addr_y_s <= std_logic_vector(unsigned(dram_y_addr_reg)+resize(unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1),32));
                z_next <= (others => '0');
            end if;
        end if;
end case;
end process;

bram_to_dram_finished <= bram_to_dram_finished_s;
sel_dram <= sel_dram_reg;
bram_addr_bram_to_dram_A <= bram_addr_bram_to_dram_A_s;
bram_addr_bram_to_dram_B <= bram_addr_bram_to_dram_B_s;
dram_out_addr_x <= dram_out_addr_x_s;
dram_out_addr_y <= dram_out_addr_y_s;
burst_len_write <= burst_len_write_s;

end Behavioral;
