version = v"6.2.1"

include("../common.jl")

# Build the tarballs!
build_tarballs(ARGS, configure(version)...;
               preferred_gcc_version=v"6", julia_compat="1.7")
