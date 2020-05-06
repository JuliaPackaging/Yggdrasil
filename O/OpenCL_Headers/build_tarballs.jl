# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OpenCL_Headers"
version = v"2020.03.13"

# Collection of sources required to build this package
sources = [
    ArchiveSource("https://github.com/KhronosGroup/OpenCL-Headers/archive/v2020.03.13.tar.gz",
                  "664bbe587e5a0a00aac267f645b7c413586e7bc56dca9ff3b00037050d06f476"),
]

# Bash recipe for building across all platforms
script = raw"""
cd OpenCL-Headers-*
install_license LICENSE

mkdir ${prefix}/include
mv CL ${prefix}/include/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/CL/cl.h", :cl_h)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
