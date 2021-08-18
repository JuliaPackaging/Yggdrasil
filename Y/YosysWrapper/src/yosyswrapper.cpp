#include "jlcxx/jlcxx.hpp"
#include <kernel/yosys.h>


USING_YOSYS_NAMESPACE

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.method("run_command", run_command);
    mod.method("yosys_setup", yosys_setup);
    //mod.method("yosys_already_setup", &Yosys::yosys_already_setup);
    mod.method("yosys_shutdown", yosys_shutdown);
    //mod.method("run_frontend", &Yosys::run_frontend);
    //mod.method("run_backend", &Yosys::run_backend);
}