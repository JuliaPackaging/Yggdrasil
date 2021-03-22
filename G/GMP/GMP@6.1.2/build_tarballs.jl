version = v"6.1.2"

include("../common.jl")

# Build the tarballs
build_tarballs(ARGS, configure(version)...;
               preferred_gcc_version=v"6", julia_compat="~1.0, ~1.1, ~1.2, ~1.3, ~1.4, ~1.5")

