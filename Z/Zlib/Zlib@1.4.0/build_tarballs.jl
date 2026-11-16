using BinaryBuilder2

version = v"1.4.0"

include("../common.jl")

build_tarballs(ARGS, configure_zlib_build(version)...; julia_compat="1.10")

# build trigger: 1
