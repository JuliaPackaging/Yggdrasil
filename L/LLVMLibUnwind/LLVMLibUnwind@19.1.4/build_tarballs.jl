version = v"19.1.4"

include("../common.jl")

# Build the tarballs
build_tarballs(ARGS, configure(version; experimental=true)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.12")
