# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FLANN"
version = v"1.9.2"

platforms = expand_cxxstring_abis(supported_platforms())

include(joinpath(@__DIR__, "..", "common.jl"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6",
)
