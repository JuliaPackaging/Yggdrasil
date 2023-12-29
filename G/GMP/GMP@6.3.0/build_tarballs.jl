version = v"6.3.0"

include("../common.jl")

# Build the tarballs!
build_tarballs(ARGS, configure(version)...;
               preferred_gcc_version=v"6", julia_compat="1.6")

