# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZlibNG"
version = v"2.1.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zlib-ng/zlib-ng.git", "74253725f884e2424a0dd8ae3f69896d5377f325"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib-ng
# Correct Power build (see <https://github.com/zlib-ng/zlib-ng/issues/1648>)
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/power.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DZLIB_ENABLE_TESTS=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libz-ng", "libzlib-ng2"], :libzng)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
