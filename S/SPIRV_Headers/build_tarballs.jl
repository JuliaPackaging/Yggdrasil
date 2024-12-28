# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "SPIRV_Headers"
version = v"1.6.0"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/KhronosGroup/SPIRV-Headers.git",
              "aa331ab0ffcb3a67021caa1a0c1c9017712f2f31"),
]

# Bash recipe for building across all platforms
script = raw"""
cd SPIRV-Headers
install_license LICENSE

CMAKE_FLAGS=()

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("include/spirv/spir-v.xml", :spirv_xml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
