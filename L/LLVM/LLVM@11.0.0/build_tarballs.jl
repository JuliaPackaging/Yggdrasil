name = "LLVM"
llvm_full_version = v"11.0.0+4"
libllvm_version = v"11.0.0+0"

# Include common LLVM stuff
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, llvm_full_version, name, libllvm_version)...; skip_audit=true)
