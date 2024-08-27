`ifndef HOG_AXIF_SEQ_ITEM_SV
    `def HOG_AXIF_SEQ_ITEM_SV

    parameter integer C_S_AXI_HP_DATA_WIDTH	= 64;	
    parameter integer C_S_AXI_HP_ADDR_WIDTH	= 32;	

    class hog_axif_seq_item extends uvm_sequence_item;
        
        // TODO: add constraints.

        // fields of sequence_item:
        // TODO: fix randomization.
        //logic	                                       s_axi_aclk;
        rand logic                                     	s_axi_aresetn;
        rand logic	[C_S_AXI_HP_ADDR_WIDTH - 1 : 0]        s_axi_awaddr;
        rand logic	[2 : 0]                                s_axi_awprot;
        rand logic	                                       s_axi_awvalid
        rand logic	                                       s_axi_awready
        rand logic [C_S_AXI_HP_DATA_WIDTH - 1 : 0]	      s_axi_wdata;
        rand logic [(C_S_AXI_HP_DATA_WIDTH/8) - 1 : 0]    s_axi_wstrb;
        rand logic	                                       s_axi_wvalid;
        rand logic	                                       s_axi_wready;
        rand logic [1 : 0]                                s_axi_bresp;
        rand logic	                                       s_axi_bvalid;
        rand logic	                                       s_axi_bready;
        rand logic	[C_S_AXI_HP_ADDR_WIDTH-1 : 0]          s_axi_araddr;
        rand logic	[2 : 0]                                s_axi_arprot;
        rand logic	                                       s_axi_arvalid;
        rand logic	                                       s_axi_arready;
        rand logic [C_S_AXI_HP_DATA_WIDTH-1 : 0]          s_axi_rdata;
        rand logic	[1 downto 0]                           s_axi_rresp;
        rand logic	                                       s_axi_rvalid;
        rand logic	                                       s_axi_rready;

        // factory registration
        `uvm_object_utils_begin(hog_axif_seq_item)
            `uvm_field_int(s_axi_aresetn, UVM_DEFAULT);
            `uvm_field_int(s_axi_awaddr, UVM_DEFAULT);
            `uvm_field_int(s_axi_awprot, UVM_DEFAULT);
            `uvm_field_int(s_axi_awvalid, UVM_DEFAULT);
            `uvm_field_int(s_axi_awready, UVM_DEFAULT);
            `uvm_field_int(s_axi_wdata, UVM_DEFAULT);
            `uvm_field_int(s_axi_wstrb, UVM_DEFAULT);
            `uvm_field_int(s_axi_wvalid, UVM_DEFAULT);
            `uvm_field_int(s_axi_wready, UVM_DEFAULT);
            `uvm_field_int(s_axi_bresp, UVM_DEFAULT);
            `uvm_field_int(s_axi_bvalid, UVM_DEFAULT);
            `uvm_field_int(s_axi_bready, UVM_DEFAULT);
            `uvm_field_int(s_axi_araddr, UVM_DEFAULT);
            `uvm_field_int(s_axi_arprot, UVM_DEFAULT);
            `uvm_field_int(s_axi_arvalid, UVM_DEFAULT);
            `uvm_field_int(s_axi_arready, UVM_DEFAULT);
            `uvm_field_int(s_axi_rdata, UVM_DEFAULT);
            `uvm_field_int(s_axi_rresp, UVM_DEFAULT);
            `uvm_field_int(s_axi_rvalid, UVM_DEFAULT);
            `uvm_field_int(s_axi_rready, UVM_DEFAULT);
        `uvm_object_utils_end

        // constructor
        function new(string name = "hog_axif_seq_item");
            super.new(name);
        endfunction : new

    endclass;

`endif