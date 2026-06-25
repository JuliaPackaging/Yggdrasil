version = v"22.1.1"

include("../common.jl")

# Built with GCC 13; see LLVM_full@22 for rationale.
build_tarballs(ARGS, configure_build(ARGS, version; assert=true, experimental_platforms=true)...;
               preferred_gcc_version=v"13", preferred_llvm_version=v"16", julia_compat="1.6")
# Build trigger: 0
