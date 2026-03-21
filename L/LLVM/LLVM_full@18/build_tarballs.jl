version = v"18.1.7"

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"17",
               julia_compat="1.6")
# Build trigger: !
