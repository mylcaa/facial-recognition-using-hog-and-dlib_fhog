#include "systemc.h"
#include "VP.hpp"

using namespace sc_core;
using namespace tlm;

int sc_main(int argc, char* argv[])
{
	Vp vp("VP");
	sc_start(50, SC_NS);
	cout << "heeej" << endl;

	return 0;
}