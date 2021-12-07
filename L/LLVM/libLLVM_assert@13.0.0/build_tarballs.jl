name = "libLLVM"
version = v"13.0.0+1"

# Include common tools.
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name; experimental_platforms=true, assert=true)...; skip_audit=true, julia_compat="1.8")
