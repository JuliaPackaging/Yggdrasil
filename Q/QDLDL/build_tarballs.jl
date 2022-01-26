# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QDLDL"
version = v"0.1.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/osqp/qdldl/archive/refs/tags/v$(version).tar.gz", "2868b0e61b7424174e9adef3cb87478329f8ab2075211ef28fe477f29e0e5c99")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd qdldl-0.1.5/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
cmake --build .
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libqdldl", :libqdldl)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
