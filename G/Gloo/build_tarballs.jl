# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gloo"
version = v"0.0.20210521"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebookincubator/gloo.git", "c22a5cfba94edf8ea4f53a174d38aa0c629d070f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gloo
atomic_patch -p1 ../patches/mingw32.patch
atomic_patch -p1 ../patches/mingw-lowercase-include.patch
atomic_patch -p1 ../patches/mingw32-link-with-ws2_32.patch
atomic_patch -p1 ../patches/musl-caddr.patch
mkdir build
cd build
if [[ $target != *w64-mingw32* ]]; then
    cmake_extra_args="-DUSE_LIBUV=ON"
fi
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    $cmake_extra_args \
    ..
cmake --build . -- -j $nproc
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # Gloo can only be built on 64-bit systems
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgloo", :libgloo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LibUV_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"5",
    julia_compat="1.6")
