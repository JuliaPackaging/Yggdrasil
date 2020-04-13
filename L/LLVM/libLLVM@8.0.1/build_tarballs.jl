name = "libLLVM"
LLVM_full_version = v"8.0.1+3"

# Include common tools
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, LLVM_full_version, name)...; skip_audit=true)
