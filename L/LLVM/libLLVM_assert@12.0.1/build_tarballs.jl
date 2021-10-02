name = "libLLVM"
version = v"12.0.1+3"

# Include common tools.
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name; experimental_platforms=true, assert=true)...; skip_audit=true, julia_compat="1.7")
