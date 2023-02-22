# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libaec"
version = v"1.0.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://gitlab.dkrz.de/k202009/libaec/-/archive/v$(version)/libaec-v$(version).tar.bz2", "31fb65b31e835e1a0f3b682d64920957b6e4407ee5bbf42ca49549438795a288")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libaec*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsz", :libsz),
    LibraryProduct("libaec", :libaec),
    ExecutableProduct("aec", :aec)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
