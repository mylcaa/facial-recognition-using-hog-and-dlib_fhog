#ifndef BRAM_HPP
#define BRAM_HPP

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_target_socket.h>
#include <vector>
#include "def.hpp"
#include <iostream>

using namespace std;

class Bram : public sc_core::sc_module
{
public:
	Bram(sc_core::sc_module_name name);
	~Bram();
	tlm_utils::simple_target_socket<Bram> interconnect_socket;
	tlm_utils::simple_target_socket<Bram> hw_socket;
protected:
	void b_transport(pl_t&, sc_core::sc_time&);
	vector <num_t> mem;
};

#endif // BRAM_HPP
