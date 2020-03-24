# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "KAShim"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/vchuravy/KAShim.git", "53a435a7bc2ab1eb1a92c784d79acf2546b4727e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/KAShim/
make CFLAGS="-I${prefix}/include -fPIC" LDFLAGS="-L${prefix}/lib -luv" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libkashim", :libkashim)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LibUV_jll", uuid="183b4373-6708-53ba-ad28-60e28bb38547"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
