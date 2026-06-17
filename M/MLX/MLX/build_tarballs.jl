# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MLX"
version = v"0.25.2"

include(joinpath(@__DIR__, "..", "common.jl"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat,
    preferred_gcc_version,
)
