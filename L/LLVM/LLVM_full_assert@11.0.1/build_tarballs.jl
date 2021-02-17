version = v"11.0.1"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true, assert=true)...;
                     preferred_gcc_version=v"7", preferred_llvm_version=v"8", julia_compat="1.6")
