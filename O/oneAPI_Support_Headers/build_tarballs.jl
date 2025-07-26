# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2025.2.0"

# Collection of sources required to complete build
sources = [
    # https://pypi.org/project/mkl-devel-dpcpp
    FileSource("https://files.pythonhosted.org/packages/08/30/a28cfc8f9a982a5998940b808288f58f4ba2607e50a18f97207b7428f602/mkl_devel_dpcpp-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "44ceb849a99f9bbe3ad89dac9dcdedb540b3996c69e699a40047d62d51934a0c"; filename="oneapi-headers.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d oneapi-headers oneapi-headers.whl
cd oneapi-headers/mkl_devel_dpcpp-2025.2.0.data/data

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
