# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FXdiv"
version = v"0.0.20181117"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Maratyszcza/FXdiv.git", "b742d1143724d646cd0f914646f1240eacf5bd73"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FXdiv
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=$libdir \
    -DFXDIV_BUILD_TESTS=OFF \
    -DFXDIV_BUILD_BENCHMARKS=OFF \
    ..
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/fxdiv.h", :fxdiv_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6")
