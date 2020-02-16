# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsodium"
version = v"1.0.18"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jedisct1/libsodium.git", "5b2ea7d73d3ffef2fb93b82b9f112f009d54c6e6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsodium

./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsodium", :libsodium)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
