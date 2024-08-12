# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LAZperf"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/hobu/laz-perf.git",
              "8dc8d055a8f9a5f86bde6ea4d45722febf9c432c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/laz-perf*

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DEMSCRIPTEN=OFF \
    -DWITH_TESTS=OFF

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("liblazperf", :liblazperf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
