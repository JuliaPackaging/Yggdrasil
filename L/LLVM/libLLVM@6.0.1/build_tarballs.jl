name = "libLLVM"
version = v"6.0.1"

# Include common tools
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name)...; skip_audit=true)
