# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "tlaplus"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tlaplus/tlaplus.git", "478d8569e84dfb31b982a500947def5c9c813b97")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
