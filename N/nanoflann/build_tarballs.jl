# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nanoflann"
version = v"1.3.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/jlblancoc/nanoflann/archive/refs/tags/v$(version).tar.gz", "e100b5fc8d72e9426a80312d852a62c05ddefd23f17cbb22ccd8b458b11d0bea")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nanoflann-*/
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_EXAMPLES=OFF \
-DBUILD_BENCHMARKS=OFF \
-DBUILD_TESTS=OFF

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
#nanoflann is a header only library, so no binary products
products = Product[]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
