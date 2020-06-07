using BinaryBuilder
using Pkg

name = "Darknet"

include("../common.jl")

version, sources, script, products, dependencies = gen_common(; gpu = false)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
