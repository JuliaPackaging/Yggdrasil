# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "snappy"
version = v"1.1.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/snappy/archive/1.1.8.tar.gz", "16b677f07832a612b0836178db7f374e414f94657c138e6993cbfc5dcc58651f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd snappy-1.1.8/
mkdir cmake-build
cd cmake-build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DSNAPPY_BUILD_TESTS=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
