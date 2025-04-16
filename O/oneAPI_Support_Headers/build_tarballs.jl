# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "oneAPI_Support_Headers"
version = v"2025.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://files.pythonhosted.org/packages/44/5c/7bfaa300e5cdc6e50328c8e85f703a852a681db92c26aa31ee33ade51fd2/mkl_devel_dpcpp-2025.1.0-py2.py3-none-manylinux_2_28_x86_64.whl",
                  "92adbc773739a247b596844e8b6b2ec34adb3bb6e6de01e0889994cafd7ca5a9"; filename="oneapi-headers.whl"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
unzip -d oneapi-headers oneapi-headers.whl
cd oneapi-headers/mkl_devel_dpcpp-2025.1.0.data/data

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
