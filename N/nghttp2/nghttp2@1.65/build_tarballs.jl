version = v"1.65.0"

include("../common.jl")

build_tarballs(ARGS, configure_nghttp2_build(version)...;
               julia_compat="1.6", preferred_llvm_version=llvm_version)

# Build trigger: 1
