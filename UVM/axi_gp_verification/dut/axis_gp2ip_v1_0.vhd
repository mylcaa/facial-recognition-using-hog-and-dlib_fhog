library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_gp2ip_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Ports towards the IP core
		-- input ports:
		status_reg : in std_logic;
        
        -- output ports:
		ctrl_reg : out std_logic;
		width_reg : out std_logic_vector(9 downto 0);
		width_4_reg : out std_logic_vector(7 downto 0);
		width_2_reg: out std_logic_vector(8 downto 0);
		height_reg : out std_logic_vector(10 downto 0);
		cycle_num_in_reg : out std_logic_vector(5 downto 0); --2*bram_width/width
		cycle_num_out_reg : out std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
		rows_num_reg : out std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
		effective_row_limit_reg : out std_logic_vector(11 downto 0); --(height/PTS_PER_ROW)/accumulated_loss
		bram_height : out std_logic_vector(4 downto 0);
		dram_in_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		dram_x_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		dram_y_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axis_gp2ip_v1_0;

architecture arch_imp of axis_gp2ip_v1_0 is

	-- component declaration
	component axis_gp2ip_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		-- Ports towards the IP core
		status_reg : in std_logic;
        -- output ports:
		ctrl_reg : out std_logic;
		width_reg : out std_logic_vector(9 downto 0);
		width_4_reg : out std_logic_vector(7 downto 0);
		width_2_reg: out std_logic_vector(8 downto 0);
		height_reg : out std_logic_vector(10 downto 0);
		cycle_num_in_reg : out std_logic_vector(5 downto 0); --2*bram_width/width
		cycle_num_out_reg : out std_logic_vector(5 downto 0); --2*(bram_width/(width-1))
		rows_num_reg : out std_logic_vector(9 downto 0); --2*(bram_width/width)*bram_height
		effective_row_limit_reg : out std_logic_vector(11 downto 0); --(height/PTS_PER_ROW)/accumulated_loss
		bram_height : out std_logic_vector(4 downto 0);
		dram_in_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		dram_x_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		dram_y_addr_reg : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		--AXI
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axis_gp2ip_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
axis_gp2ip_v1_0_S00_AXI_inst : axis_gp2ip_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		status_reg => status_reg,
		ctrl_reg => ctrl_reg,
		width_reg => width_reg,
		width_4_reg => width_4_reg,
    	width_2_reg => width_2_reg,
		height_reg => height_reg,
		cycle_num_in_reg => cycle_num_in_reg,
		cycle_num_out_reg => cycle_num_out_reg,
		rows_num_reg => rows_num_reg,
		effective_row_limit_reg => effective_row_limit_reg,
		bram_height => bram_height,
		dram_in_addr_reg => dram_in_addr_reg,
		dram_x_addr_reg => dram_x_addr_reg,
		dram_y_addr_reg  => dram_y_addr_reg,

		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
