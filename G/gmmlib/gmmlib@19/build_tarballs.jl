# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../common.jl")

version = v"19.4.1"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/intel/gmmlib.git",
              "ebfcfd565031dbd7b45089d9054cd44a501f14a9"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5")
