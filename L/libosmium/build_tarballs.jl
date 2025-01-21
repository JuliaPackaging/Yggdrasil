# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libosmium"
version = v"2.21.1" # 'Fake' bump from 2.21.0 to rebuild with boost

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/osmcode/libosmium.git", "2675b6eaecdc677e14751272bca66d2192c8a58a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libosmium

mkdir build && cd build

cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/osmium/version.hpp", :osmium_version),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("boost_jll"; compat="=1.79.0"),
    BuildDependency(PackageSpec(name="protozero_jll", uuid="e2028600-4f28-5e5c-ab86-957950af6e0a")),
    BuildDependency("Lz4_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6.1.0")
