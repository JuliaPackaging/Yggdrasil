using Pkg
using BinaryBuilder

include("../common.jl")
# original: GCC 7, Clang 9
build_tarballs(
    ARGS, configure_build(v"5.5.1")...;
    preferred_gcc_version=v"8", preferred_llvm_version=v"9", julia_compat="1.9")
