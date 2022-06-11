# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JonkerVolgenant"
version = v"1.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/fypc/Jonker-Volgenant.git", "8dd04610f678d7d35992ae4ad3af8f5eecc9b553")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Jonker-Volgenant/src
mkdir -p "${libdir}"
cc -I -Wall -std=c99 -shared -fPIC -O3 -o "${libdir}/bipartite_assignement.${dlext}" *.c
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("bipartite_assignement", :bipartite_assignement),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
