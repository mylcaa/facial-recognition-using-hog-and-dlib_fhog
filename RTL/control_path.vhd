library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_path is
  Port ( 
    clk: in std_logic;
    reset: in std_logic;
    start: in std_logic;
    en_axi: in std_logic; 

    --reg bank
    width: in std_logic_vector(9 downto 0);
    width_4: in std_logic_vector(7 downto 0);
    width_2: in std_logic_vector(8 downto 0);
    height: in std_logic_vector(10 downto 0);
    bram_height: in std_logic_vector(3 downto 0);
    dram_in_addr: in std_logic_vector(31 downto 0);
    dram_x_addr: in std_logic_vector(31 downto 0);
    dram_y_addr: in std_logic_vector(31 downto 0);
    cycle_num_limit: in std_logic_vector(5 downto 0); --2*bram_width/width
    cycle_num_out: in std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
    rows_num: in std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
    effective_row_limit: in std_logic_vector(9 downto 0); --(height/PTS_PER_ROW)/accumulated_loss

    ready: out std_logic; 
    
    --dram_to_bram_out
    sel_bram_in: out std_logic_vector(2 downto 0);
    burst_len: out std_logic_vector(7 downto 0);
    bram_addr_A: out std_logic_vector(9 downto 0);
    bram_addr_B: out std_logic_vector(9 downto 0);
    dram_addr0: out std_logic_vector(31 downto 0);
    dram_addr1: out std_logic_vector(31 downto 0);
    we_in: out std_logic_vector(31 downto 0);
    we_out: out std_logic_vector(15 downto 0); 
    
    --control logic
    --dodati signale  burst_len??
    --dodati muxeve
    sel_filter: out std_logic_vector(2 downto 0);
    sel_bram_out: out std_logic_vector(2 downto 0);
    bram_output_addr_A: out std_logic_vector(9 downto 0);
    bram_output_addr_B: out std_logic_vector(9 downto 0);
    
    --dram_to_bram
    sel_dram: out std_logic_vector(4 downto 0);
    dram_out_addr_x: out std_logic_vector(31 downto 0);
    dram_out_addr_y: out std_logic_vector(31 downto 0)
    );
end control_path;

architecture Behavioral of control_path is

--general states
type state_t is 
       (idle, dram_to_bram, control_logic);
signal state_r, state_n : state_t;

--states dram to bram
type state_dram_to_bram_t is 
    (loop_dram_to_bram0, loop_dram_to_bram1, loop_dram_to_bram2, loop_dram_to_bram3, 
       end_dram_to_bram1, end_dram_to_bram2, end_dram_to_bram3, loop_dram_to_bram_axi, loop_dram_to_bram_axi_we);
signal state_dram_to_bram_r, state_dram_to_bram_n : state_dram_to_bram_t;

--states control_logic
type state_control_logic_t is
    (init_loop_x, control_loop, init_loop_row, loop_row, end_row);
signal state_control_logic_r, state_control_logic_n: state_control_logic_t;

--states bram_to_dram
type state_bram_to_dram_t is
    (init_loop_bram_to_dram1, loop_bram_to_dram1, loop_bram_to_dram2, 
    loop_bram_to_dram3, end_bram_to_dram2, end_bram_to_dram3);
signal state_bram_to_dram_r, state_bram_to_dram_n: state_bram_to_dram_t;

--addr signals
signal bram_addr_A_s, bram_addr_B_s: std_logic_vector(9 downto 0);
signal bram_addr_control_logic: std_logic_vector(9 downto 0);
signal bram_addr_bram_to_dram_A, bram_addr_bram_to_dram_B: std_logic_vector(9 downto 0);
signal dram_addr0_s, dram_addr1_s: std_logic_vector(31 downto 0);
signal dram_out_addr_x_s, dram_out_addr_y_s: std_logic_vector(31 downto 0);

--sel signals
signal sel_bram_in_reg, sel_bram_in_next: std_logic_vector(3 downto 0); 
signal sel_filter_reg, sel_filter_next: std_logic_vector(2 downto 0);
signal sel_bram_out_reg, sel_bram_out_next: std_logic_vector(2 downto 0);
signal sel_dram_reg, sel_dram_next: std_logic_vector(4 downto 0);

signal dram_row_ptr0_reg, dram_row_ptr0_next: std_logic_vector(10 downto 0);
signal dram_row_ptr1_reg, dram_row_ptr1_next: std_logic_vector(10 downto 0);

signal init: std_logic;
signal finished: std_logic;
signal burst_len_read, burst_len_write: std_logic_vector(7 downto 0);

--reg bank
signal width_reg, width_next: std_logic_vector(9 downto 0);
signal width_2_reg, width_2_next: std_logic_vector(8 downto 0);
signal width_4_reg, width_4_next: std_logic_vector(9 downto 0);
signal height_reg, height_next: std_logic_vector(10 downto 0);
signal rows_num_reg, rows_num_next: std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
signal effective_row_limit_reg, effective_row_limit_next: std_logic_vector(9 downto 0); --(height/PTS_PER_ROW)/accumulated_loss
signal bram_height_reg, bram_height_next: std_logic_vector(3 downto 0);
signal cycle_num_limit_reg, cycle_num_limit_next: std_logic_vector(5 downto 0);
signal cycle_num_out_reg, cycle_num_out_next: std_logic_vector(5 downto 0);

signal i_reg, i_next: std_logic_vector(4 downto 0);
signal j_reg, j_next: std_logic_vector(3 downto 0);
signal k_reg, k_next: std_logic_vector(9 downto 0);

signal we_in_reg, we_in_next: std_logic_vector(31 downto 0);
signal we_out_reg, we_out_next: std_logic_vector(15 downto 0);

signal x_reg, x_next: std_logic_vector(9 downto 0);
signal row_position_reg, row_position_next: std_logic_vector(8 downto 0);

signal cycle_num_reg, cycle_num_next: std_logic_vector(5 downto 0);
signal sel_bram_addr_in_reg, sel_bram_addr_in_next: std_logic; 
signal counter_init_reg, counter_init_next: std_logic_vector(5 downto 0);

--signals bram_to_dram
signal y_reg, y_next: std_logic_vector(5 downto 0);
signal row_cnt_reg, row_cnt_next: std_logic_vector(10 downto 0); --provjeri
signal z_reg, z_next: std_logic_vector(8 downto 0);

begin

--init
process(clk) 
begin

if(rising_edge(clk)) then
    if reset = '1' then
        state_r <= idle;
        state_dram_to_bram_r <= loop_dram_to_bram0;
        state_control_logic_r <= state_control_logic_n;

        sel_bram_in_reg <= (others => '0');
        sel_filter_reg <= (others => '0');
        sel_bram_out_reg <= (others => '0');
        sel_dram_reg <= (others => '0');

        we_in_reg <= (others => '0');
        we_out_reg <= (others => '0');

        i_reg <= (others => '0');
        j_reg <= (others => '0');
        k_reg <= (others => '0');

        x_reg <= (others => '0');
        row_position_reg <= (others => '0');

        y_reg <= (others => '0');
        row_cnt_reg <= (others => '0');
        z_reg <= (others => '0');

        cycle_num_reg <= (others => '0');
        sel_bram_addr_in_reg <= '0';
        counter_init_reg <= (others => '0');

        dram_row_ptr0_reg <= (others => '0');
        dram_row_ptr1_reg <= "0000000001";
        init <= '1';
        burst_len_read <= "11111111";
        burst_len_write <= "11111111";
    else

        state_r <= state_n;
        state_dram_to_bram_r <= state_dram_to_bram_n;
        state_bram_to_dram_r <= state_bram_to_dram_n;

        width_reg <= width_next;
        width_2_reg <= width_2_next;
        width_4_reg <= width_4_next;
        rows_num_reg <= rows_num_next;
        height_reg <= height_next;
        bram_height_reg <= bram_height_next;
        cycle_num_limit_reg <= cycle_num_limit_next;
        cycle_num_out_reg <= cycle_num_out_next;
        effective_row_limit_reg <= effective_row_limit_next;

        sel_bram_in_reg <= sel_bram_in_next;
        sel_filter_reg <= sel_filter_next;
        sel_bram_out_reg <= sel_bram_out_next;
        sel_dram_reg <= sel_dram_next;

        we_in_reg <= we_in_next;
        we_out_reg <= we_out_next;

        i_reg <= i_next;
        j_reg <= j_next;
        k_reg <= k_next;

        x_reg <= x_next;
        row_position_reg <= row_position_next;

        y_reg <= y_next;
        row_cnt_reg <= row_cnt_next;
        z_reg <= z_next;

        cycle_num_reg <= cycle_num_next;
        sel_bram_addr_in_reg <= sel_bram_addr_in_next;
        counter_init_reg <= counter_init_next;

        dram_row_ptr0_reg <= dram_row_ptr0_next; 
        dram_row_ptr1_reg <= dram_row_ptr1_next; 

        burst_len_read <= std_logic_vector(unsigned(width_4_reg) - 1);
        burst_len_write <= std_logic_vector(unsigned(width_4_reg) - 2);
    end if;
end if;
end process;

process(state_r) --dodati ostale sinale
begin

state_n <= state_r;

width_next <= width_reg;
width_2_next <= width_2_reg;
width_4_next <= width_4_reg;
rows_num_next <= rows_num_reg;
height_next <= height_reg;
bram_height_next <= bram_height_reg;
cycle_num_limit_next <= cycle_num_limit_reg;
cycle_num_out_next <= cycle_num_out_reg;
effective_row_limit_next <= effective_row_limit_reg;

ready <= '0';

sel_bram_in_next <= sel_bram_in_reg;

case state_r is
    when idle =>    
        width_next <= width;
        width_2_next <= width_2;
        width_4_next <= width_4;
        rows_num_next <= rows_num;
        height_next <= height;
        bram_height_next <= bram_height;
        cycle_num_limit_next <= cycle_num_limit;
        cycle_num_out_next <= cycle_num_out;
        effective_row_limit_next <= effective_row_limit;
    
        ready <= '1';
    
        if(start = '1') then
            state_n <= dram_to_bram;
        end if;

    when dram_to_bram =>
        state_dram_to_bram_n <= state_dram_to_bram_r;
        sel_bram_in_next <= sel_bram_in_reg;
        we_in_next <= we_in_reg;
        we_out_next <= we_out_reg;
        i_next <= i_reg;
        j_next <= j_reg;
        k_next <= k_reg;
        dram_row_ptr0_next <= dram_row_ptr0_reg;
        dram_row_ptr1_next <= dram_row_ptr1_reg;

    case state_dram_to_bram_r is
        when loop_dram_to_bram0 =>
            i_next <= (others => '0');
            sel_bram_in_next <= (others => '0');
            state_dram_to_bram_n <= loop_dram_to_bram1;

        when loop_dram_to_bram1 =>
            j_next <= (others => '0');
            state_dram_to_bram_n <= loop_dram_to_bram2;

        when loop_dram_to_bram2 =>
            dram_addr0_s <= std_logic_vector(unsigned(dram_row_ptr0_reg)*unsigned(width_4_reg));
            dram_addr1_s <= std_logic_vector(unsigned(dram_row_ptr1_reg)*unsigned(width_4_reg));
            state_dram_to_bram_n <= loop_dram_to_bram_axi;

        when loop_dram_to_bram_axi=>
            if(en_axi = '1') then
                state_dram_to_bram_n <= loop_dram_to_bram_axi_we;
            end if;

        when loop_dram_to_bram_axi_we => 
            k_next <= (others => '0');
            we_in_next <= X"0000000F";
            state_dram_to_bram_n <= loop_dram_to_bram3;

        when loop_dram_to_bram3 =>
            bram_addr_A_s <= std_logic_vector(unsigned(i_reg)*unsigned(width_2_reg) + unsigned(k_reg)); 
            bram_addr_B_s <= std_logic_vector(unsigned(i_reg)*unsigned(width_2_reg) + unsigned(k_reg) + 1);  
            k_next <= std_logic_vector(unsigned(k_reg) + 2);
            
            if(k_next = width_2_reg) then
                state_dram_to_bram_n <= end_dram_to_bram3;
            end if;
        when end_dram_to_bram3 =>
            dram_row_ptr0_next <= std_logic_vector(unsigned(dram_row_ptr0_reg) + 2);
            dram_row_ptr1_next <= std_logic_vector(unsigned(dram_row_ptr1_reg) + 2);
            sel_bram_in_next <= std_logic_vector(unsigned(sel_bram_in_reg) + 1);
            we_in_next <= std_logic_vector(shift_left(unsigned(we_in_reg),4));
            
            if(dram_row_ptr1_next = height_reg) then
                state_dram_to_bram_n <= end_dram_to_bram1;
            end if;

            if(sel_bram_in_next = "1000") then
                sel_bram_in_next <= (others => '0');
                we_in_next <= X"0000000F";
            end if;
            
            j_next <= std_logic_vector(unsigned(j_reg) + 2);
            
            if(j_next = bram_height_reg) then
                state_dram_to_bram_n <= end_dram_to_bram2;
            else
                state_dram_to_bram_n <= loop_dram_to_bram2;
            end if;

        when end_dram_to_bram2 =>
            i_next <= std_logic_vector(unsigned(i_reg) + 1);
            if(i_next = cycle_num_limit_reg) then
                state_dram_to_bram_n <= end_dram_to_bram1;
            else
                state_dram_to_bram_n <= loop_dram_to_bram1;
            end if;

        when end_dram_to_bram1 =>
            if(init = '1') then
                init <= '0';
                state_n <= control_logic;
            else
                state_n <= control_logic;
                state_control_logic_n <= init_loop_row;
            end if;
    end case;
    
    when control_logic =>
        state_control_logic_n <= state_control_logic_r;
        x_next <= x_reg;
        row_position_next <= row_position_reg;
        cycle_num_next <= cycle_num_reg;
        sel_bram_addr_in_next <= sel_bram_addr_in_reg;
        sel_filter_next <= sel_filter_reg;
        counter_init_next <= counter_init_reg;

    case state_control_logic_r is

        when init_loop_x =>
            x_next <= (others => '0');
            state_control_logic_n <= control_loop;

        when control_loop =>
            cycle_num_next <= x_reg(9 downto 4);
            if(cycle_num_next = std_logic_vector(unsigned(cycle_num_limit_reg) - 1) and x_reg = std_logic_vector(12*unsigned(cycle_num_next))) then
                if(dram_row_ptr1_reg < height_reg) then --da li ovo treba staviti i fore poslije when?
                    counter_init_next <= std_logic_vector(unsigned(counter_init_reg) + 1); 
                    dram_row_ptr0_next <= std_logic_vector((unsigned(rows_num_reg) - 4) * unsigned(counter_init_next));
                    dram_row_ptr1_next <= std_logic_vector((unsigned(rows_num_reg) - 4) * unsigned(counter_init_next) + 1);
                    x_next <= std_logic_vector(unsigned(x_reg) + 4);
                    cycle_num_next <= (others => '0');
                    sel_filter_next <= (others => '0');
                    sel_bram_out_next <= (others => '0');
                    state_n <= dram_to_bram; 
                    state_dram_to_bram_n <= loop_dram_to_bram0;
                else 
                    state_control_logic_n <= init_loop_row;
                end if;
            else
                state_control_logic_n <= init_loop_row;
            end if;

        when init_loop_row =>
            row_position_next <= (others => '0');
            sel_bram_addr_in_next <= '1';
            we_in_next <= (others => '0');
            state_control_logic_n <= loop_row;

        when loop_row =>
            if (sel_filter_reg = "011") then
                --nove adrese
            else
                bram_addr_A_s <= std_logic_vector(unsigned(cycle_num_reg)*unsigned(width_2)+unsigned(row_position_reg));
                bram_addr_B_s <= std_logic_vector(unsigned(cycle_num_reg)*unsigned(width_2)+unsigned(row_position_reg)+1);
            end if;
            bram_addr_control_logic <= std_logic_vector(unsigned(cycle_num_reg)*(unsigned(width_2_reg)-1)+shift_left(unsigned(we_in_reg),1));

            row_position_next <= std_logic_vector(unsigned(row_position_reg)+2);
            if(row_position_next = std_logic_vector(unsigned(width_2_reg)-1)) then 
                state_control_logic_n <= end_row;
            end if;

        when end_row =>
            sel_filter_next <= std_logic_vector(unsigned(sel_filter_reg) + 1);
            if(sel_filter_next = "100") then
                sel_filter_next <= (others => '0');
            end if;
            sel_bram_out_next <= std_logic_vector(unsigned(sel_bram_out_reg) + 1);
            we_out_next <= std_logic_vector(shift_left(unsigned(we_in_reg),4));

            if(sel_bram_out_next = "100") then
                sel_bram_out_next <= (others => '0');
                we_out_next <= x"000F";
            end if;
            x_next <= std_logic_vector(unsigned(x_reg)+4);
            if(x_next = effective_row_limit_reg) then
                finished <= '1';
            else
                state_control_logic_n <= init_loop_x;
            end if;
    end case;
end case;
end process;

process(state_bram_to_dram_r) --dodati signale
begin

state_bram_to_dram_n <= state_bram_to_dram_r;
sel_dram_next <= sel_dram_reg;
we_out_next <= we_out_reg;
y_next <= y_reg;
row_cnt_next <= row_cnt_reg;
z_next <= z_reg;

case state_bram_to_dram_r is
    when init_loop_bram_to_dram1 =>
        y_next <= (others => '0');
        we_out_next <= (others => '0');
        state_bram_to_dram_n <= loop_bram_to_dram1;
    when loop_bram_to_dram1 =>
        sel_dram_next <= (others => '0');
        state_bram_to_dram_n <= loop_bram_to_dram2;
    when loop_bram_to_dram2 =>
        dram_out_addr_x_s <= std_logic_vector(unsigned(width_reg)*unsigned(height_reg) + unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1));
        dram_out_addr_y_s <= std_logic_vector(unsigned(width_reg)*unsigned(height_reg) + (unsigned(width_reg)-2)*(unsigned(height_reg)-2) + unsigned(row_cnt_reg)*(unsigned(width_4_reg)-1));
        z_next <= (others => '0');
        state_bram_to_dram_n <= loop_bram_to_dram3;
    when loop_bram_to_dram3 =>
        bram_addr_bram_to_dram_A <= std_logic_vector(unsigned(y_reg)*(unsigned(width_2_reg)-1)+unsigned(z_reg));
        bram_addr_bram_to_dram_B <= std_logic_vector(unsigned(y_reg)*(unsigned(width_2_reg)-1)+unsigned(z_reg)+1);
        if(z_next = std_logic_vector(unsigned(width_2_reg) - 1)) then
            state_bram_to_dram_n <= end_bram_to_dram3;
        end if;
    when end_bram_to_dram3 =>
        row_cnt_next <= std_logic_vector(unsigned(row_cnt_reg)+1);
        sel_dram_next <= std_logic_vector(unsigned(sel_dram_reg)+1);
        if(sel_dram_next = bram_height_reg) then
            state_bram_to_dram_n <= end_bram_to_dram2;
        else
            state_bram_to_dram_n <=loop_bram_to_dram2;
        end if;
    when end_bram_to_dram2 =>
        z_next <= std_logic_vector(unsigned(z_reg)+1);
        if(z_next = cycle_num_out_reg) then
            if(finished = '0') then
                --???
            end if;
        else
            state_bram_to_dram_n <= loop_bram_to_dram1;
        end if;
end case;
end process;

bram_addr_A <= bram_addr_A_s;
bram_addr_B <= bram_addr_B_s;
dram_addr0 <= dram_addr0_s;
dram_addr1 <= dram_addr0_s;
--sa muxa bram_addr_control_logic i bram_addr_bram_to_dram_A, bram_addr_bram_to_dram_B
--bram_output_addr_A
bram_output_addr_B <= bram_addr_bram_to_dram_B;
dram_out_addr_x <= dram_out_addr_x_s;
dram_out_addr_y <= dram_out_addr_y_s;

sel_bram_in <= sel_bram_in_reg;
sel_filter <= sel_filter_reg;
sel_bram_out <= sel_bram_out_reg;
sel_dram <= sel_dram_reg;

we_in <= we_in_reg;
we_out <= we_out_reg;

end Behavioral;