version = v"11.0.0-rc5"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version)...;
                     preferred_gcc_version=v"7", preferred_llvm_version=v"8")
