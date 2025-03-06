version = v"6.2.0"

llvm_version = v"13.0.1"

include("../common.jl")

# Build the tarballs!
build_tarballs(ARGS, configure(version, llvm_version)...;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6",
               preferred_llvm_version=llvm_version)
