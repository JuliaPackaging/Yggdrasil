version = v"19.2.1" # We had to bump the minor version number to change compat bounds for riscv64 support, but from next version we can go back to follow upstream version number

include("../common.jl")

build_tarballs(ARGS, configure_build(ARGS, version; assert=true, experimental_platforms=true)...;
               preferred_gcc_version=v"13", preferred_llvm_version=v"18", julia_compat="1.6")
# Build trigger: 6
