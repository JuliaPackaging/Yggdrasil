using BinaryBuilder

name = "LibSpatialIndex"
version = v"1.9.3"

# Collection of sources required to build LibSpatialIndex
sources = [
    ArchiveSource("https://github.com/libspatialindex/libspatialindex/releases/download/1.9.3/spatialindex-src-1.9.3.tar.bz2",
        "4a529431cfa80443ab4dcd45a4b25aebbabe1c0ce2fa1665039c80e999dcc50a")
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd spatialindex-src-*

# patch < ${WORKSPACE}/srcdir/makefile.patch
# rm Makefile.am.orig

# if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
#   patch < ${WORKSPACE}/srcdir/header-check.patch
# fi


mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
cmake --build . --target install
install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libspatialindex_c", :libspatialindex_c),
    LibraryProduct("libspatialindex", :libspatialindex),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
