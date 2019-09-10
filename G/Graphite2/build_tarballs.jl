# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Graphite2"
version = v"1.3.13"

# Collection of sources required to build Graphite2
sources = [
    "https://github.com/silnrsi/graphite/releases/download/$(version)/graphite2-$(version).tgz" =>
    "dd63e169b0d3cf954b397c122551ab9343e0696fb2045e1b326db0202d875f06"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphite2-*/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !(p isa Windows)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libgraphite2", :libgraphite2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
