version = v"22.1.1"

include("../common.jl")

# Built with GCC 10, matching LLVM 15-21. We initially tried GCC 13 to match the
# mingw-w64 v13 GCCBootstrap that PoCL (#14048) statically links against, but that
# was unnecessary: PoCL only uses GCC 13 on Windows (for `.drectve -exclude-symbols`
# to dodge export-ordinal limits) and otherwise GCC 10, and it already links the
# GCC-10-built LLVM 20. The `std::__get_once_mutex` ABI break seen when statically
# linking LLVM into a GCC-13 build is a toolchain bug (the GCC-13 libstdc++ was
# rebuilt with TLS without backporting the call_once ABI patch), being fixed
# upstream -- not a reason to rebuild LLVM with GCC 13. GCC 10 keeps the GLIBCXX
# floor low and stays on the well-tested toolchain.
build_tarballs(ARGS, configure_build(ARGS, version; experimental_platforms=true)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"18", julia_compat="1.6")
# Build trigger: 0
