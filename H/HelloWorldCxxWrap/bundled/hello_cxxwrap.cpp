#include <string>

#include "jlcxx/jlcxx.hpp"

std::string greet()
{
    return "hello, world";
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.method("greet", &greet);
}
