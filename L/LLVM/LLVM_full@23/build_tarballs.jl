version = v"23.1.1"

include("../common.jl")

# Built with GCC 10, matching LLVM 15-22 (see LLVM_full@22 for why GCC 13 was
# tried and reverted). preferred_llvm_version=v"18" because the aarch64 backend of
# the clang 16 bootstrap cannot codegen compiler-rt's `preserve_all` handlers.
build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.6")
# Build trigger: 1
