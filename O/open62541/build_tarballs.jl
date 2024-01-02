# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "open62541"
version = v"1.3.9"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/open62541/open62541.git",
              "70ff3501ddecd7e7594ebc63e2365994d59e010d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/open62541/
mkdir build && cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUA_MULTITHREADING=100 \
    -DUA_ENABLE_SUBSCRIPTIONS=ON \
    -DUA_ENABLE_METHODCALLS=ON \
    -DUA_ENABLE_PARSING=ON \
    -DUA_ENABLE_NODEMANAGEMENT=ON \
    -DUA_ENABLE_AMALGAMATION=ON \
    -DUA_ENABLE_IMMUTABLE_NODES=ON \
    -DUA_ENABLE_HISTORIZING=ON \
    -DUA_ENABLE_ENCRYTPION=MBEDTLS \
    -DBUILD_SHARED_LIBS=ON \
    -DUA_FORCE_WERROR=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libopen62541", :libopen62541)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("MbedTLS_jll"; compat="~2.28"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
