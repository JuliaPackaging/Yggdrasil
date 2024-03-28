# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2024.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://anaconda.org/intel/mkl-devel-dpcpp/2024.1.0/download/linux-64/mkl-devel-dpcpp-2024.1.0-intel_691.tar.bz2",
                  "abae8c0903e438bce8acfdf2b790d10863669490a87f19a908942268d5fabc82")
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
