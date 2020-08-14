# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WORLD"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mmorise/World.git", "1f8815f7a85e344ea9f98ca6b1383578a161d4e2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd World/
ls
mkdir -p ${libdir}
gcc -O1 -Wall -shared -fPIC -o ${libdir}/libworld.${dlext} -Isrc src/*.cpp
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libworld", :libworld)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
