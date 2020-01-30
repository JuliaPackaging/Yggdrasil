# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libdivsufsort"
version = v"2.0.2"

# Collection of sources required to complete build
sources = [
    "https://github.com/y-256/libdivsufsort.git" =>
    "522cac82e5f4980fb7dc4f9f982aa63069b2d4ad",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libdivsufsort/
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libdivsufsort", :libdivsufsort)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
