using BinaryBuilder

name = "LibSpatialIndex"
version = v"2.0.0"

# Collection of sources required to build LibSpatialIndex
sources = [
    ArchiveSource("https://github.com/libspatialindex/libspatialindex/releases/download/$(version)/spatialindex-src-$(version).tar.bz2",
        "949e3fdcad406a63075811ab1b11afcc4afddc035fbc69a3acfc8b655b82e9a5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd spatialindex-src-*
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    ..
cmake --build . -j${nproc}
cmake --build . --target install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libspatialindex_c", :libspatialindex_c),
    LibraryProduct("libspatialindex", :libspatialindex),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
