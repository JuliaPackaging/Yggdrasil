name = "LLVM"
llvm_full_version = v"11.0.1+1"
libllvm_version = v"11.0.1+1"

# Include common LLVM stuff
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, llvm_full_version, name, libllvm_version; experimental_platforms=true, assert=true)...; skip_audit=true)
