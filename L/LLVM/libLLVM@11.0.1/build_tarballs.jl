name = "libLLVM"
version = v"11.0.1+3"

# Include common tools.
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name; experimental_platforms=true)...; skip_audit=true, julia_compat="1.6")
