# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2025.2.0"

# Collection of sources required to complete build
sources = [
    # https://pypi.org/project/mkl-devel-dpcpp
    FileSource("https://files.pythonhosted.org/packages/2d/f2/ef6e3d305a5b987f0638d4de1ada1e4cd00925acb0f6dc55f67ef8c420e1/mkl_devel_dpcpp-2025.2.0-py2.py3-none-win_amd64.whl",
               "78d4c3a746e15594c3e54db10843f4a81a494aba4ec3bb8f002a0ae19f63b933"; filename="oneapi-headers.whl"),
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
