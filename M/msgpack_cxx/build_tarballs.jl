# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msgpack_cxx"
version = v"6.1.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/msgpack/msgpack-c/releases/download/cpp-$(version)/msgpack-cxx-$(version).tar.gz",
                  "5fd555742e37bbd58d166199e669f01f743c7b3c6177191dd7b31fb0c37fa191"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/msgpack-cxx-*
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DMSGPACK_BUILD_DOCS=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    # This is a header-only library without any binary products
    FileProduct("include/msgpack.hpp", :msgpack_hpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="~1.76.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
