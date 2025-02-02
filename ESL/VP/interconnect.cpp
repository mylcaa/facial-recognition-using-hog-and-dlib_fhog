#include "interconnect.hpp"

Interconnect::Interconnect(sc_core::sc_module_name name)
    : sc_module(name)
    //, offset(sc_core::SC_ZERO_TIME)
{
    soft_socket.register_b_transport(this, &Interconnect::b_transport);
    SC_REPORT_INFO("Interconnect", "Constructed.");
}

Interconnect::~Interconnect()
{
    SC_REPORT_INFO("Interconnect", "Destroyed.");
}

void Interconnect::b_transport(pl_t& pl, sc_core::sc_time& offset)
{
    sc_dt::uint64 addr = pl.get_address();
    sc_dt::uint64 taddr = addr & 0x00FFFFFF;

    if (addr >= DRAM_LOW_ADDR && addr <= DRAM_HIGH_ADDR)
    {
        pl.set_address(taddr);
        dram_ctrl_socket->b_transport(pl, offset);
    }
    else if (addr >= HARD_LOW_ADDR && addr <= HARD_HIGH_ADDR)
    {
        pl.set_address(taddr);
        hw_socket->b_transport(pl, offset);
    }
    else
    {
        SC_REPORT_ERROR("Interconnect", "Wrong address.");
        pl.set_response_status(tlm::TLM_ADDRESS_ERROR_RESPONSE);
    }

    offset += sc_core::sc_time(DELAY_IC, sc_core::SC_NS); 
}
