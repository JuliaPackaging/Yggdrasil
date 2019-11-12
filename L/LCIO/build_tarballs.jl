# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LCIO"
version = v"02.12.01"

# Collection of sources required to build LCIO
sources = [
    "https://github.com/iLCSoft/LCIO/archive/v02-12-01.tar.gz" =>
    "8a3d2e66c2f2d4489fc2e1c96335472728d913d4090327208a1d93b3b0728737",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/LCIO-*/
mkdir build && cd build

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("liblcio", :liblcio),
    LibraryProduct("libsio", :libsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
