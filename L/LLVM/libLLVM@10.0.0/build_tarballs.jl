name = "libLLVM"
version = v"10.0.0"


# Include common tools
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name)...; skip_audit=true)
