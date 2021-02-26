name = "Clang"
llvm_full_version = v"11.0.1+2"
libllvm_version = v"11.0.1+2"

# Include common LLVM stuff
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, llvm_full_version, name, libllvm_version; experimental_platforms=true)...; skip_audit=true)
