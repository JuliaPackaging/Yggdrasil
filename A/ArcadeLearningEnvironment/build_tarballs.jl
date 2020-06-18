# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ArcadeLearningEnvironment"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/mgbellemare/Arcade-Learning-Environment/archive/v0.6.1.tar.gz", "8059a4087680da03878c1648a8ceb0413a341032ecaa44bef4ef1f9f829b6dde"),
    ArchiveSource("https://zlib.net/zlib-1.2.11.tar.gz", "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd zlib-1.2.11/
./configure --prefix=${prefix}
make
make install
cd ../Arcade-Learning-Environment-0.6.1/
cmake -DUSE_SDL=OFF -DBUILD_EXAMPLES=OFF -DBUILD_CPP_LIB=OFF -DBUILD_CLI=OFF -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-isystem\ ../zlib-1.2.11/ .
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:powerpc64le, libc=:glibc),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libale_c", :libale)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
