# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MMG"
version = v"5.6.0"

# Collection of sources required to build MMG
sources = [
    ArchiveSource("https://github.com/MmgTools/mmg/archive/refs/tags/v$(version).tar.gz",
                  "bbf9163d65bc6e0f81dd3acc5a51e4a8c47a7fdae849abc26277e01154fe2437"),
    ArchiveSource("https://github.com/ISCDtoolbox/Commons/archive/refs/heads/master.zip",
                  "02fae58388a93692f3c73dcb4619bbcf838b479744cf6972edeca330f756125a"),
    ArchiveSource("https://github.com/ISCDtoolbox/LinearElasticity/archive/refs/heads/master.zip",
                  "b1898151fbc4294d05d1df2eade209f2e0e185e6e49f38b6fd36a1333dd591fd"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
# Install dependencies
cd ${WORKSPACE}/srcdir/Commons-*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/Commons.patch"
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install

cd ${WORKSPACE}/srcdir/LinearElasticity-*
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/LinearElasticity.patch"
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
make -j${nproc}
make install

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
if [[ ! "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/SCOTCH.patch"
fi
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DUSE_VTK=OFF
make -j${nproc}
make install
cd ..
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude= p -> (Sys.iswindows(p) || Sys.isfreebsd(p)))

# The products that we will ensure are always built
products = [
    LibraryProduct("libmmg", :libmmg),
    LibraryProduct("libmmg2d", :libmmg2d),
    LibraryProduct("libmmg3d", :libmmg3d),
    LibraryProduct("libmmgs", :libmmgs),
    LibraryProduct("libCommons", :libCommons),
    LibraryProduct("libElas", :libElas),
    ExecutableProduct("mmg2d_O3", :mmg2d_O3),
    ExecutableProduct("mmg3d_O3", :mmg3d_O3),
    ExecutableProduct("mmgs_O3", :mmgs_O3),
    ExecutableProduct("elastic", :elastic)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("SCOTCH_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
