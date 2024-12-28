# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "H3"
version = v"4.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/uber/h3.git", "5c91149104ac02c4f06faa4fc557e69cf6b131ef")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/h3*/
export CFLAGS="-std=c99"
export LDFLAGS="-lm"
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=1 \
    -DENABLE_COVERAGE=0 \
    -DBUILD_BENCHMARKS=0 \
    -DBUILD_TESTING=0 \
    -DBUILD_FILTERS=0 \
    -DBUILD_GENERATORS=0 \
    ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libh3", :libh3)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
