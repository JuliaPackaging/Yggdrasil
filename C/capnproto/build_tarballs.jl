# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "capnproto"
version = v"1.3.0"

# Collection of sources required to build capnproto
sources = [
    ArchiveSource("https://capnproto.org/capnproto-c++-$(version).tar.gz",
                  "098f824a495a1a837d56ae17e07b3f721ac86f8dbaf58896a389923458522108"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/capnproto-*/

# Native build for tools
mkdir native_install
cmake -S . -B build_native \
    -DCMAKE_CXX_COMPILER=${CXX_BUILD} \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/native_install \
    -DBUILD_TESTING=OFF \
    -DCAPNP_LITE=ON

cmake --build build_native -j${nproc}
cmake --build build_native --target install

# Cross-compilation
cmake -S . -B build_cross \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTING=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.14 \
    -DCAPNP_EXECUTABLE=$(pwd)/native_install/bin/capnp \
    -DCAPNPC_CXX_EXECUTABLE=$(pwd)/native_install/bin/capnpc-c++ \
    -DWITH_OPENSSL=ON

cmake --build build_cross -j
cmake --build build_cross --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcapnp", :libcapnp),
    LibraryProduct("libcapnp-rpc", :libcapnp_rpc),
    LibraryProduct("libcapnpc", :libcapnpc),
    LibraryProduct("libkj", :libkj),
    LibraryProduct("libkj-async", :libkj_async),
    ExecutableProduct("capnp", :capnp)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("CMake_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
              preferred_gcc_version=v"9", julia_compat="1.6")
