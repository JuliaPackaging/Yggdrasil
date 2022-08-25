using Pkg
using BinaryBuilder

include("../common.jl")
build_tarballs(
    ARGS, configure_build(v"4.5.2")...;
    preferred_gcc_version=v"9", preferred_llvm_version=v"12", julia_compat="1.8")
