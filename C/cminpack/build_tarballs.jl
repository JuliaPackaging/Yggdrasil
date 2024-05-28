# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cminpack"
version = v"1.3.8"

# Collection of sources required to complete build
sources = [
    # We get 1.3.8, but it needs some patches
    GitSource("https://github.com/devernay/cminpack.git", "cb7c3f6433ccea7eef58ff57b3a9a4c2563eb375"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cminpack

# Upstream in master branch: https://github.com/devernay/cminpack/commit/dceef97837ac97eef3921bb22abf4a25851c8c76
atomic_patch -p1 $WORKSPACE/srcdir/patches/01_CMakePath.patch

# Upstream master branch commits that are needed even though FindMKL is getting deleted in patch 4
atomic_patch -p1 $WORKSPACE/srcdir/patches/02_blas_mkl1.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/03_blas_mkl2.patch

# Upstream in master branch: https://github.com/devernay/cminpack/commit/e086bb29f2191f1d4df484d15bfe1ae4397e48ad
atomic_patch -p1 $WORKSPACE/srcdir/patches/04_blas.patch

# Upstream in master branch: https://github.com/devernay/cminpack/commit/04200d5aa625fc86c2d81ffbf9dd5c70816fe4ce
atomic_patch -p1 $WORKSPACE/srcdir/patches/05_libdir.patch

# Upstream PR https://github.com/devernay/cminpack/pull/62
atomic_patch -p1 $WORKSPACE/srcdir/patches/06_freebsd.patch


# Build single precision library
mkdir build_s
cmake -B build_s/ -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMINPACK_PRECISION="s" \
    -DBUILD_EXAMPLES=OFF \
    -DUSE_BLAS=OFF
cmake --build build_s/ --parallel ${nproc}
cmake --install build_s/

# Build double precision library
mkdir build_d
cmake -B build_d/ -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMINPACK_PRECISION="d" \
    -DBUILD_EXAMPLES=OFF \
    -DUSE_BLAS=OFF
cmake --build build_d/ --parallel ${nproc}
cmake --install build_d/

install_license CopyrightMINPACK.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcminpack", :libcminpack),
    LibraryProduct("libcminpacks", :libcminpacks),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
