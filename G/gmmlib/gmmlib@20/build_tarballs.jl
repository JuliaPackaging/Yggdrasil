# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../common.jl")

version = v"20.1.1"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/intel/gmmlib.git",
              "09324e1fe8129b66bdf6b16ed533d56ce654eaa4"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")
