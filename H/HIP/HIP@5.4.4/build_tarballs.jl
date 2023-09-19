using Pkg
using BinaryBuilder

include("../common.jl")

build_tarballs(
    ARGS, configure_build(v"5.4.4")...;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.9")
