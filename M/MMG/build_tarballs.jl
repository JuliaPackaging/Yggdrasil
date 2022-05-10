# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MMG"
version = v"5.6.0"

# Collection of sources required to build MMG
sources = [
    ArchiveSource("https://github.com/MmgTools/mmg/archive/refs/tags/v$(version).tar.gz",
                  "bbf9163d65bc6e0f81dd3acc5a51e4a8c47a7fdae849abc26277e01154fe2437"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# Install genheader for host platform
cp -r ${WORKSPACE}/srcdir/mmg-* ${WORKSPACE}/srcdir/mmg-genheader
cd ${WORKSPACE}/srcdir/mmg-genheader
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/genheader.patch"
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${host_prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
cd ${WORKSPACE}/srcdir && rm -r ${WORKSPACE}/srcdir/mmg-genheader

# Install MMG
cd ${WORKSPACE}/srcdir/mmg-*
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/MMG.mingw.patch"
    USE_SCOTCH=OFF
else
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/MMG.patch"
    USE_SCOTCH=ON
fi
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DUSE_SCOTCH=${USE_SCOTCH} \
    -DUSE_ELAS=ON \
    -DUSE_VTK=OFF
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmmg", :libmmg),
    LibraryProduct("libmmg2d", :libmmg2d),
    LibraryProduct("libmmg3d", :libmmg3d),
    LibraryProduct("libmmgs", :libmmgs),
    ExecutableProduct("mmg2d_O3", :mmg2d_O3),
    ExecutableProduct("mmg3d_O3", :mmg3d_O3),
    ExecutableProduct("mmgs_O3", :mmgs_O3)
]

# SCOTCH is only available on non-Windows platforms
scotch_platforms = filter(p -> !Sys.iswindows(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LinearElasticity_jll"),
    Dependency("SCOTCH_jll", platforms=scotch_platforms)
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"9")
