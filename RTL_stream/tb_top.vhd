library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
use std.textio.all;

entity tb_top is
  generic(DATA_WIDTH:natural:=32;
          BRAM_SIZE:natural:=1024;
          ADDR_WIDTH:natural:=10;
          PIX_WIDTH:natural:=16);
--  Port ( );
end tb_top;

architecture Behavioral of tb_top is

component top is
  generic(DATA_WIDTH:natural:=32;
          BRAM_SIZE:natural:=1024;
          ADDR_WIDTH:natural:=10;
          PIX_WIDTH:natural:=16);
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
    bram_height: in std_logic_vector(4 downto 0);
    dram_in_addr: in std_logic_vector(31 downto 0);
    dram_x_addr: in std_logic_vector(31 downto 0);
    dram_y_addr: in std_logic_vector(31 downto 0);
    cycle_num_limit: in std_logic_vector(5 downto 0); --2*bram_width/width
    cycle_num_out: in std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
    rows_num: in std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
    effective_row_limit: in std_logic_vector(9 downto 0); --(height/PTS_PER_COL)*PTS_PER_COL+accumulated_loss 
    
    burst_len_read: out std_logic_vector(7 downto 0);
    burst_len_write: out std_logic_vector(7 downto 0);
    
    dram_addr0: out std_logic_vector(31 downto 0);
    dram_addr1: out std_logic_vector(31 downto 0);
    
    dram_out_addr_x: out std_logic_vector(31 downto 0);
    dram_out_addr_y: out std_logic_vector(31 downto 0);

    ready: out std_logic; 
    
    --data signals
    data_in1: in std_logic_vector(63 downto 0);
    data_in2: in std_logic_vector(63 downto 0);
    data_out1: out std_logic_vector(63 downto 0);
    data_out2: out std_logic_vector(63 downto 0));

end component;

signal clk_s: std_logic;
signal reset_s: std_logic;
signal start_s: std_logic;
signal en_axi_s: std_logic;

signal width_s: std_logic_vector(9 downto 0);
signal width_4_s: std_logic_vector(7 downto 0);
signal width_2_s: std_logic_vector(8 downto 0);
signal height_s: std_logic_vector(10 downto 0);
signal bram_height_s: std_logic_vector(4 downto 0);
signal dram_in_addr_s: std_logic_vector(31 downto 0);
signal dram_x_addr_s: std_logic_vector(31 downto 0); --height*width
signal dram_y_addr_s: std_logic_vector(31 downto 0); --height*width+(height-2)*(width-2)
signal cycle_num_limit_s: std_logic_vector(5 downto 0); --2*bram_width/width
signal cycle_num_out_s: std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
signal rows_num_s: std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
signal effective_row_limit_s: std_logic_vector(9 downto 0); --(height/PTS_PER_COL)*PTS_PER_COL+accumulated_loss 

signal burst_len_read_s: std_logic_vector(7 downto 0);
signal burst_len_write_s: std_logic_vector(7 downto 0);
    
signal dram_addr0_s: std_logic_vector(31 downto 0);
signal dram_addr1_s: std_logic_vector(31 downto 0);
    
signal dram_out_addr_x_s: std_logic_vector(31 downto 0);
signal dram_out_addr_y_s: std_logic_vector(31 downto 0);

type data_t is array(0 to 1) of std_logic_vector(2*DATA_WIDTH-1 downto 0);
signal data_in_s, data_out_s: data_t;

signal ready_s: std_logic; 

constant IMG_WIDTH : natural := 248;
constant IMG_HEIGHT : natural := 302;

type rows_type is array(0 to IMG_WIDTH - 1) of std_logic_vector(15 downto 0);
type dram_type is array(0 to IMG_HEIGHT - 1) of rows_type;

impure function dram_init return dram_type is
    variable row_text : line;
    variable float_data : real;
    variable check : boolean;
    variable data : std_logic_vector(15 downto 0);
    variable dram_rows : rows_type;
    variable dram : dram_type;
    file text_file : text open read_mode is "/home/koshek/Desktop/emotion_recognition_git/facial-recognition-using-hog-and-dlib_fhog/input_files/input246_300/gray_normalised.txt";
begin
    for row in 0 to IMG_HEIGHT - 1 loop
        readline(text_file, row_text);
        if row_text.all'length = 0 then -- skip empty lines if there are any
            next;
         end if;
        for column in 0 to IMG_WIDTH - 1 loop
            read(row_text, float_data, check);
            data := std_logic_vector(to_signed(integer(32768.0*float_data), 16));
            dram_rows(column) := data;
        end loop;
        dram(row) := dram_rows;
    end loop;
    return dram;
end function;

signal dram1 : dram_type := dram_init;
signal dram2 : dram_type := dram_init;
signal dram3 : dram_type := dram_init;

begin

top_l: top
generic map(
          DATA_WIDTH => DATA_WIDTH,
          BRAM_SIZE => BRAM_SIZE,
          ADDR_WIDTH => ADDR_WIDTH,
          PIX_WIDTH => PIX_WIDTH)

port map(    
    clk => clk_s,
    reset => reset_s,
    start => start_s,
    en_axi => en_axi_s,

    --reg bank
    width => width_s,
    width_4 => width_4_s,
    width_2 => width_2_s,
    height => height_s,
    bram_height => bram_height_s,
    dram_in_addr => dram_in_addr_s,
    dram_x_addr => dram_x_addr_s,
    dram_y_addr => dram_y_addr_s,
    cycle_num_limit => cycle_num_limit_s,
    cycle_num_out => cycle_num_out_s,
    rows_num => rows_num_s,
    effective_row_limit => effective_row_limit_s,
    
    burst_len_read => burst_len_read_s,
    burst_len_write => burst_len_write_s,
    
    dram_addr0 => dram_addr0_s,
    dram_addr1 => dram_addr1_s,
    
    dram_out_addr_x => dram_out_addr_x_s,
    dram_out_addr_y => dram_out_addr_y_s,

    ready => ready_s,
    
    --data signals
        data_in1 => data_in_s(0),
        data_in2 => data_in_s(1),
        data_out1 => data_out_s(0),
        data_out2 => data_out_s(1));
        
    stim_gen1: process
        variable a : integer := 0;
        variable b: integer := 0;
        variable c: integer := 0;
        variable d: integer := 0;
        variable e: integer := 0;
    begin
        reset_s <= '0', '1' after 10ns, '0' after 30ns;
        start_s <= '0', '1' after 45ns, '0' after 75ns;
        en_axi_s <= '1';
        
        for c in 0 to 3 loop
            --report "a: " & integer'image(a) & " b: " & integer'image(b) & " c: " & integer'image(c) & " d: " & integer'image(d) & " e: " & integer'image(e);
        
            data_in_s(0) <= x"0000000000000000"; 
            data_in_s(1) <= x"0000000000000000";
                               
                    width_s <= "0011111000";
                    width_4_s <= "00111110";
                    width_2_s <= "001111100";
                    height_s <= "00100101110";
                    bram_height_s <= "10000"; 
                    dram_in_addr_s <= x"00000000";
                    dram_x_addr_s <= x"00012490";
                    dram_y_addr_s <= x"000244D8";
                    cycle_num_limit_s <= "001000";
                    cycle_num_out_s <= "001000";
                    rows_num_s <= "0010000000";
                    effective_row_limit_s <= "0100110100";
            wait until falling_edge(clk_s);
        end loop;
        
            for a in 0 to 63 loop
                for b in 0 to 61 loop
                    report "a: " & integer'image(a) & " b: " & integer'image(b) & " d: " & integer'image(d) & " e: " & integer'image(e);
                    
                    
                    data_in_s(0) <= dram1(2*a)(4*b)&dram1(2*a)(4*b+1)&dram1(2*a)(4*b+2)&dram1(2*a)(4*b+3); 
                    data_in_s(1) <= dram1(2*a+1)(4*b)&dram1(2*a+1)(4*b+1)&dram1(2*a+1)(4*b+2)&dram1(2*a+1)(4*b+3);
                    
                    width_s <= "0011111000";
                    width_4_s <= "00111110";
                    width_2_s <= "001111100";
                    height_s <= "00100101110";
                    bram_height_s <= "10000"; 
                    dram_in_addr_s <= x"00000000";
                    dram_x_addr_s <= x"00012490";
                    dram_y_addr_s <= x"000244D8";
                    cycle_num_limit_s <= "001000";
                    cycle_num_out_s <= "001000";
                    rows_num_s <= "0010000000";
                    effective_row_limit_s <= "0100110100";
                wait until falling_edge(clk_s);
                end loop;
            end loop;  
            
            --wait for 196970 ns;
            wait for 196975 ns;
            
            for d in 64 to 127 loop
                for e in 0 to 61 loop
                    report " d: " & integer'image(d) & " e: " & integer'image(e);
                    
                    data_in_s(0) <= dram2(2*d)(4*e)&dram2(2*d)(4*e+1)&dram2(2*d)(4*e+2)&dram2(2*d)(4*e+3); 
                    data_in_s(1) <= dram2(2*d+1)(4*e)&dram2(2*d+1)(4*e+1)&dram2(2*d+1)(4*e+2)&dram2(2*d+1)(4*e+3);
                wait until rising_edge(clk_s);
                end loop;
            end loop; 
            
            wait for 408000 ns;
            
            for d in 128 to 150 loop
                for e in 0 to 61 loop
                    data_in_s(0) <= dram3(2*d)(4*e)&dram3(2*d)(4*e+1)&dram3(2*d)(4*e+2)&dram3(2*d)(4*e+3); 
                    data_in_s(1) <= dram3(2*d+1)(4*e)&dram3(2*d+1)(4*e+1)&dram3(2*d+1)(4*e+2)&dram3(2*d+1)(4*e+3);
                wait until rising_edge(clk_s);
                end loop;
            end loop;   
 
    wait;
    end process;

    clk_gen: process
    begin
        clk_s <= '0', '1' after 25 ns;
        wait for 50 ns;
    end process;

end Behavioral;