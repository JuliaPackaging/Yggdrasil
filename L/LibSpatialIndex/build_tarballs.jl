using BinaryBuilder

name = "LibSpatialIndex"
version = v"1.9.3"

# Collection of sources required to build LibSpatialIndex
sources = [
    ArchiveSource("https://github.com/libspatialindex/libspatialindex/releases/download/$(version)/spatialindex-src-$(version).tar.bz2",
        "4a529431cfa80443ab4dcd45a4b25aebbabe1c0ce2fa1665039c80e999dcc50a"),
    DirectorySource("./patches")
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd spatialindex-src-*

if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
    # apply https://github.com/libspatialindex/libspatialindex/pull/185 for mingw builds
    # to succeed
    atomic_patch -p1 ${WORKSPACE}/srcdir/0001-fix-mingw-build-185.patch
    # fix for https://github.com/JuliaPackaging/Yggdrasil/pull/7520#issuecomment-1760495334
    atomic_patch -p1 ${WORKSPACE}/srcdir/0002-set-win-bin-dir.patch
fi


mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
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
