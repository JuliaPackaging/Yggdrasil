# build recipe for cmt, a C library wrapping the Apple Metal APIs
# - originally from https://github.com/recp/cmt
# - modified and extended for use in Julia at
#   https://github.com/JuliaGPU/Metal.jl/tree/main/deps/cmt

using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "cmt"
repo = "https://github.com/JuliaGPU/Metal.jl"
version = v"0.2"

# Collection of sources required to build cmd
sources = [
    GitSource(repo, "23184baad0e70fc4437774db91bf7c75caa62e81"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz",
                  "9b86eab03176c56bb526de30daa50fa819937c54b280364784ce431885341bf6"),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64",  "macos"; ),
    Platform("aarch64", "macos"; )
]
platforms = expand_cxxstring_abis(platforms)

# Bash recipe for building across all platforms
script = raw"""
cd Metal.jl/deps/cmt

install_license LICENSE

CMAKE_FLAGS=()
# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING:BOOL=ON)
# replace the Yggdrasil-provided macOS SDK with a newer one
apple_sdk_root=$WORKSPACE/srcdir/MacOSX11.1.sdk
sed -i "s!/opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root!$apple_sdk_root!" $CMAKE_TARGET_TOOLCHAIN
CMAKE_FLAGS+=(-DCMAKE_SYSROOT=$apple_sdk_root)
CMAKE_FLAGS+=(-DCMAKE_FRAMEWORK_PATH=$apple_sdk_root/System/Library/Frameworks)
CMAKE_FLAGS+=(-DCMAKE_OSX_DEPLOYMENT_TARGET=11.1)

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}

ninja -C build -j ${nproc} install
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libcmt", :libcmt)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
