# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libmdbx"
version = v"0.9.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/erthink/libmdbx/releases/download/v$version/libmdbx-amalgamated-$version.tar.gz",
        "c35cc53d66d74ebfc86e39441ba26276541ac7892bf91dba1e70c83665a02767"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $WORKSPACE/srcdir/build
cd $WORKSPACE/srcdir/build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DMDBX_ENABLE_TESTS=OFF -DMDBX_BUILD_CXX=OFF ..
cmake --build . --target install -- -j${nproc}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmdbx", :libmdbx),
    ExecutableProduct("mdbx_chk", :mdbx_chk),
    ExecutableProduct("mdbx_copy", :mdbx_copy),
    ExecutableProduct("mdbx_dump", :mdbx_dump),
    ExecutableProduct("mdbx_load", :mdbx_load),
    ExecutableProduct("mdbx_stat", :mdbx_stat),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
