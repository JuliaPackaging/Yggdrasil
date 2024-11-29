# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2025.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2025.0.0-intel_939.tar.bz2",
                  "149c3d52dcc7db2d30329e686f721dc3addc017ba19034b7517c9d287f29f7d6")
]

# Bash recipe for building across all platforms
script = raw"""
mkdir $includedir
cp -r include/oneapi $includedir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/oneapi/mkl.hpp", :mkl_hpp)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
