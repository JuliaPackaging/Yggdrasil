# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "snappy"
version = v"1.1.9"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/snappy.git",
              "2b63814b15a2aaae54b7943f0cd935892fae628f"),
    #ArchiveSource("https://github.com/google/snappy/archive/$(version).tar.gz",
    #              "75c1fbb3d618dd3a0483bff0e26d0a92b495bbe5059c8b4f1c962b478b6e06e7"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd snappy*
git submodule update --init
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/snappy.patch
export CXXFLAGS="-I${includedir}"
mkdir cmake-build
cd cmake-build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DSNAPPY_BUILD_BENCHMARKS=OFF \
    -DSNAPPY_BUILD_TESTS=OFF \
    ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsnappy", :libsnappy)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="LZO_jll", uuid="dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
