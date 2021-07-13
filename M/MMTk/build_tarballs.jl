# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MMTk"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmtk/mmtk-core.git", "a5572804a18ee8210f9cb616098a1a546dd60618")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd mmtk-core/
cargo build
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:rust])
