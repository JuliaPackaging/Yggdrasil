version = v"16.0.6"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"16", julia_compat="1.10")
#Let's build!! 3
