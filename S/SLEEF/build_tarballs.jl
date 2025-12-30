# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLEEF"
version = v"3.9.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/shibatch/sleef.git", "906ca7512ee483296780a81a21b9ca715d40dfe1"),
    # We need C++20
    FileSource("https://github.com/alexey-lysiuk/macos-sdk/releases/download/14.5/MacOSX14.5.tar.xz",
               "f6acc6209db9d56b67fcaf91ec1defe48722e9eb13dc21fb91cfeceb1489e57e"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sleef

if [[ "${target}" == *-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System /opt/${target}/${target}/sys-root/usr/include/libxml2
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX14.5.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX14.5.sdk/System MacOSX14.5.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=14.5
fi

# The respective file does not exist any more on the master branch
atomic_patch -p1 ../patches/windows.patch

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

install_license $WORKSPACE/srcdir/sleef/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# 32-bit platforms are not supported any more
filter!(p -> nbits(p) > 32, platforms)
# On Windows there is a problem with exception handling. SLEEF wants
# to use sjlj, but GCC doesn't provide the respective run-time
# functions.
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsleef", :libsleef),
    LibraryProduct("libsleefdft", :libsleefdft),
    LibraryProduct("libsleefquad", :libsleefquad),
    LibraryProduct("libsleefscalar", :libsleefscalar),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD systems),
    # and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# SLEEF uses C++20 and requires at least GCC 11
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
