# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "msgpack"
version = v"6.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/msgpack/msgpack-c/releases/download/c-$(version)/msgpack-c-$(version).tar.gz",
                  "a349cd9af28add2334c7009e331335af4a5b97d8558b2e9804d05f3b33d97925"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/msgpack-c-*
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMSGPACK_BUILD_DOCS=OFF \
    -DMSGPACK_BUILD_EXAMPLES=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmsgpack-c", :libmsgpack_c),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
