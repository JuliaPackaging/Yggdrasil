# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Faiss"
version = v"1.9.0"

include(joinpath(@__DIR__, "..", "common.jl"))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.9",
    preferred_gcc_version=v"7",
)
