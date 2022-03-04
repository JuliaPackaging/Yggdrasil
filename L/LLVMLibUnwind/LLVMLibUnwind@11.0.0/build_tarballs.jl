version = v"11.0.0"

include("../common.jl")

# Build the tarballs
build_tarballs(ARGS, configure(version; experimental=true)...;
               preferred_gcc_version=v"6.1.0", julia_compat="1.6")
