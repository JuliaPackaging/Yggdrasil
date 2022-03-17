# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PThreadPool"
version = v"0.0.20201005"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Maratyszcza/pthreadpool.git", "fa75e65a58a5c70c09c30d17a1fe1c1dff1093ae"),
    GitSource("https://github.com/Maratyszcza/FXdiv.git", "b408327ac2a15ec3e43352421954f5b1967701d1"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ $target == x86_64-apple-darwin* ]]; then
    PTHREADPOOL_SYNC_PRIMITIVE=condvar
else
    PTHREADPOOL_SYNC_PRIMITIVE=default
fi

cd $WORKSPACE/srcdir/pthreadpool
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
    -DPTHREADPOOL_SYNC_PRIMITIVE=$PTHREADPOOL_SYNC_PRIMITIVE \
    ..
cmake --build . -- -j $nproc
make install
if [[ $target == *-w64-mingw32 ]]; then
    install -Dvm 755 libpthreadpool.dll "${libdir}/libpthreadpool.dll"
fi
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

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
