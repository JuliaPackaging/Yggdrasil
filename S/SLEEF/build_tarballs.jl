# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLEEF"
version = v"3.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/shibatch/sleef.git", "c5494730bf601599a55f4e77f357b51ba590585e"),
    DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sleef
if [[ $target == arm-* ]]; then
    atomic_patch -p1 ../patches/arm-neon32vfpv4.patch
fi
mkdir build-native
cd build-native
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -G Ninja \
    -DSLEEF_BUILD_DFT=TRUE \
    -DSLEEF_BUILD_QUAD=TRUE \
    -DSLEEF_BUILD_SCALAR_LIB=TRUE \
    -DSLEEF_BUILD_SHARED_LIBS=TRUE \
    -DSLEEF_BUILD_TESTS=OFF \
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
    -DSLEEF_BUILD_DFT=TRUE \
    -DSLEEF_BUILD_QUAD=TRUE \
    -DSLEEF_BUILD_SCALAR_LIB=TRUE \
    -DSLEEF_BUILD_SHARED_LIBS=TRUE \
    -DSLEEF_BUILD_TESTS=OFF \
    ..
ninja all
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(arch(p) == "i686" && Sys.iswindows(p)), platforms) # i686-windows build fails

# The products that we will ensure are always built
products = [
    LibraryProduct("libsleef", :libsleef),
    LibraryProduct("libsleefdft", :libsleefdft),
    LibraryProduct("libsleefquad", :libsleefquad),
    LibraryProduct("libsleefscalar", :libsleefscalar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("MPFR_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.15"), # we need 3.0.15 for aarch64-unknown-freebsd
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7.4",
    julia_compat="1.6")
