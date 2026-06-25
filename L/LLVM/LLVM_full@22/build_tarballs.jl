version = v"22.1.1"

include("../common.jl")

# Built with GCC 13: LLVM 22 is only consumed by recent Julia (the libLLVM/Clang/
# etc. major version tracks the Julia version), which bundles a GCC-13-era
# libstdc++, so the raised GLIBCXX floor (3.4.32) costs us nothing. GCC 13 is also
# required on Windows to match the mingw-w64 v13 GCCBootstrap shards that
# downstream consumers (e.g. PoCL) statically link against.
build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"13", preferred_llvm_version=v"16", julia_compat="1.6")
# Build trigger: 0
