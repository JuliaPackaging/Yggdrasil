using Pkg
using BinaryBuilder

include("../common.jl")
# RoCMLLVM 5.5.1 is built on LLVM 16 which is not what Julia 1.9 uses
build_tarballs(
    ARGS, configure_build(v"5.5.1")...;
    preferred_gcc_version=v"8", preferred_llvm_version=v"9", julia_compat="1.9")
