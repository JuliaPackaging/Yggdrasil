# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2024.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://software.repos.intel.com/python/conda/linux-64/mkl-devel-dpcpp-2024.2.1-intel_103.tar.bz2",
                  "abb784cc37c2bb9d05daa4271ad9ee917eecb9a907c8706230fed162f820d11e")
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
