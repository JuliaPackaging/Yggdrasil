# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "brotli"
version = v"1.0.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/google/brotli/archive/refs/tags/v$(version).tar.gz", "f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd brotli-*
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j`nprocs`
make install
install_license ./LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libbrotlidec", :libbrotlidec),
    LibraryProduct("libbrotlicommon", :libbrotlicommon),
    LibraryProduct("libbrotlienc", :libbrotlienc),
    ExecutableProduct("brotli", :brotli)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
