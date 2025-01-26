# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Faiss"
version = v"1.9.0"

include(joinpath(@__DIR__, "..", "common.jl"))

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"10", # Not using v"7", since OpenBLAS v0.3.29+ on PowerPC64LE requires libgfortran5, and not using v"8", and v"9" due to internal compiler errors on aarch64-linux-gnu
)
