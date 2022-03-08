# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLEEF"
version = v"3.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/shibatch/sleef.git", "8df2bce4596ec6b86f357beebf2e428564f0a4ec"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sleef
mkdir build-native
cd build-native
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -G Ninja \
    -DBUILD_TESTS=OFF \
    -DBUILD_DFT=TRUE \
    -DBUILD_QUAD=TRUE \
    ..
ninja all

cd $WORKSPACE/srcdir/sleef
mkdir build-cross
cd build-cross
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja \
    -DNATIVE_BUILD_DIR=$WORKSPACE/srcdir/sleef/build-native \
    -DSLEEF_SHOW_CONFIG=1 \
    -DBUILD_TESTS=OFF \
    -DBUILD_DFT=TRUE \
    -DBUILD_QUAD=TRUE \
    ..
ninja all
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsleef", :libsleef),
    LibraryProduct("libsleefdft", :libsleefdft),
    LibraryProduct("libsleefquad", :libsleefquad),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("MPFR_jll"),
    Dependency("OpenSSL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7.4",
    julia_compat="1.6")
