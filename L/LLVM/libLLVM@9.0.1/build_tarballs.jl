name = "libLLVM"
version = v"9.0.1"

include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, version, name)...; skip_audit=true)
