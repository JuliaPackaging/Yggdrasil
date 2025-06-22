version = v"12.0.1"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.6")
