# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2025.2.0"

# Collection of sources required to complete build
sources = [
    # https://pypi.org/project/onemkl-sycl-include
    FileSource("https://files.pythonhosted.org/packages/67/60/183badc2d807be1abb95a20315e84a2075cb44a1d1ede104d42cb1ed3092/onemkl_sycl_include-2025.2.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "4e995c02e5f43265aa830a06e538b2e5ada76b7c2785c26b788d6073ba605b0f"; filename="oneapi-headers.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d oneapi-headers oneapi-headers.whl
cd oneapi-headers/onemkl_sycl_include-2025.2.0.data/data

mkdir $includedir
cp -r include/oneapi $includedir

install_license $WORKSPACE/srcdir/oneapi-headers/onemkl_sycl_include-2025.2.0.dist-info/LICENSE.txt
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
