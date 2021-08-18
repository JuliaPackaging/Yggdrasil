#include "jlcxx/jlcxx.hpp"
#include <kernel/yosys.h>

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.method("run_command", &Yosys::run_command);
    mod.method("yosys_setup", &Yosys::yosys_setup);
    //mod.method("yosys_already_setup", &Yosys::yosys_already_setup);
    mod.method("yosys_shutdown", &Yosys::yosys_shutdown);
    //mod.method("run_frontend", &Yosys::run_frontend);
    //mod.method("run_backend", &Yosys::run_backend);
}