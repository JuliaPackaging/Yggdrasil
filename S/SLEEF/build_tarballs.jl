# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLEEF"
version = v"3.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/shibatch/sleef.git", "906ca7512ee483296780a81a21b9ca715d40dfe1"),
    #TODO FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
    #TODO            "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
    DirectorySource("bundled"),
]

There are problems on 32-bit systems, on 64-bit Windows, and on MacOS.
On MacOS we probably need the MacOSX12 SDK and we don't know how to download it.

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sleef

#TODO if [[ "${target}" == *-apple-darwin* ]]; then
#TODO     rm -rf /opt/${target}/${target}/sys-root/System
#TODO     tar --extract --file=${WORKSPACE}/srcdir/MacOSX11.3.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX11.3.sdk/System MacOSX11.3.sdk/usr
#TODO     export MACOSX_DEPLOYMENT_TARGET=11.3
#TODO fi

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
]

# Build the tarballs, and possibly a `build.jl` as well.
# SLEEF uses modern C++ features and requires at least GCC 11
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
