# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Snowball"
version = v"2.0.0"

# Collection of sources required to build SDL2
sources = [
    "https://snowballstem.org/dist/libstemmer_c.tgz" =>
    "054e76f2a05478632f2185025bff0b98952a2b7aed7c4e0960d72ba565de5dfc",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libstemmer_c/
cp ../CMakeLists.txt .
rm Makefile
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=/opt/$target/$target.cmake
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libstemmer", "stemmer"], :libstemmer)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
