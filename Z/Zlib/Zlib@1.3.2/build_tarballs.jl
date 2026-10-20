version = v"1.3.2"

include("../common.jl")

build_tarballs(ARGS, configure_zlib_build(version)...;
               julia_compat="1.9", preferred_llvm_version=llvm_version)

# build trigger: 1
