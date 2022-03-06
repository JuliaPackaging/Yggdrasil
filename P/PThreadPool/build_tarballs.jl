# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PThreadPool"
version = v"0.0.20191029"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Maratyszcza/pthreadpool.git", "d465747660ecf9ebbaddf8c3db37e4a13d0c9103"),
    GitSource("https://github.com/Maratyszcza/FXdiv.git", "b742d1143724d646cd0f914646f1240eacf5bd73"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pthreadpool
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DFXDIV_SOURCE_DIR=$WORKSPACE/srcdir/FXdiv \
    -DPTHREADPOOL_LIBRARY_TYPE=shared \
    -DPTHREADPOOL_BUILD_TESTS=OFF \
    -DPTHREADPOOL_BUILD_BENCHMARKS=OFF \
    ..
cmake --build . -- -j $nproc
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !Sys.iswindows(p), platforms) # Windows fails to build

# The products that we will ensure are always built
products = [
    LibraryProduct("libpthreadpool", :libpthreadpool),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"5",
    julia_compat="1.6")
