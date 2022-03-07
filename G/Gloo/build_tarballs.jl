# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gloo"
version = v"0.0.20200317"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookincubator/gloo.git", "113bde13035594cafdca247be953610b53026553"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gloo
mkdir build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DUSE_LIBUV=ON \
    ..
cmake --build . -- -j $nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # Gloo can only be built on 64-bit systems
filter!(!Sys.iswindows, platforms) # Windows support will be available from 20200910, i.e. 881f7f0dcf06f7e49e134a45d3284860fb244fa9
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgloo", :libgloo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibUV_jll", v"2.0.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"5",
    julia_compat="1.6")
