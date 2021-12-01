# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wolfSSL"
version = v"4.8.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/wolfSSL/wolfssl/archive/refs/tags/v$(version)-stable.tar.gz", "50db45f348f47e00c93dd244c24108220120cb3cc9d01434789229c32937c444")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wolfssl*

mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DWOLFSSL_EXAMPLES=no \
-DWOLFSSL_CRYPT_TESTS=no \
-DBUILD_SHARED_LIBS=ON

make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental = true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libwolfssl", :libwolfssl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
