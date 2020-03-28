using BinaryBuilder

name = "ECOS"
version = v"2.0.7"

# Collection of sources required to build ECOSBuilder
sources = [
    GitSource("https://github.com/embotech/ecos.git", "2954b2a640f2194bf91dbf51e682be17012d7698")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ecos*
make shared

mkdir -p ${libdir}
cp libecos.${dlext} ${libdir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libecos", :libecos)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
