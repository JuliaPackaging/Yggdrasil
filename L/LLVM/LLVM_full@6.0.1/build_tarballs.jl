version = v"6.0.1"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version)...;
                     preferred_gcc_version=v"7", preferred_llvm_version=v"8")
