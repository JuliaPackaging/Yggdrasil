# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2026.1.0"

# Collection of sources required to complete build
sources = [
    # https://pypi.org/project/onemkl-sycl-include/2026.1.0/
    FileSource("https://files.pythonhosted.org/packages/5e/2b/5ecba7eebf0a14eb394d5d5c36aa3469e1b3dd4eb9e9898a2ed22a9d87b4/onemkl_sycl_include-2026.1.0-py2.py3-none-manylinux_2_28_x86_64.whl",
               "e2ed8aec7531613c908086d542539548397482afc765528dbdbe913752566298"; filename="oneapi-headers.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d oneapi-headers oneapi-headers.whl
cd oneapi-headers/onemkl_sycl_include-2026.1.0.data/data

mkdir $includedir
cp -r include/oneapi $includedir

install_license $WORKSPACE/srcdir/oneapi-headers/onemkl_sycl_include-2026.1.0.dist-info/LICENSE.txt
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")

