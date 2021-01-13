# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "OSQP"
version = v"0.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dl.bintray.com/bstellato/generic/OSQP/$(version)/osqp-$(version).tar.gz",
                  "2026ec67784344fbe062708947a68420911f8feb040e07ff09fba35254032b1f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd osqp-*
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libqdldl", :qdldl),
    LibraryProduct("libosqp", :osqp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
