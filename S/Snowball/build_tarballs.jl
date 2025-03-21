# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Snowball"
version = v"2.2.0"

# Collection of sources required to build SDL2
sources = [
    ArchiveSource("https://snowballstem.org/dist/libstemmer_c-2.2.0.tar.gz", "b941d9fe9cf36b4e2f8d3873cd4d8b8775bd94867a1df8d8c001bb8b688377c3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libstemmer_c-2.2.0/
cp ../CMakeLists.txt .
rm Makefile
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
