# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
version = v"9.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/apache/arrow/archive/refs/tags/apache-arrow-9.0.0.zip", "fb2469e9bfeb3e9a45f1e3086f536a329d59a0efd3c905436d3b6e8dd030be41")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/arrow-apache-arrow-*/cpp

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DARROW_BUILD_UTILITIES=ON
-DARROW_BUILD_STATIC=OFF
-DARROW_DATASET=ON
-DARROW_WITH_BZ2=ON
-DARROW_WITH_LZ4=ON
-DARROW_WITH_ZSTD=ON
-DARROW_WITH_ZLIB=ON
-DARROW_WITH_SNAPPY=ON
-DARROW_PARQUET=ON)

cmake . ${CMAKE_FLAGS[@]}

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libparquet", :libparquet),
    LibraryProduct("libarrow", :libarrow)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll")
    Dependency("Zlib_jll")
    Dependency("Zstd_jll")
    Dependency("snappy_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
