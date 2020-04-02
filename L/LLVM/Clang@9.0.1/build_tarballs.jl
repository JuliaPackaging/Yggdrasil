name = "Clang"
libllvm_version = v"9.0.1+4"

include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, libllvm_version, name)...; skip_audit=true)
