# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Clingcon"
version = v"5.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/potassco/clingcon.git", "586b23ceadff349051dd0a58467679a3758199cb")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/clingcon
mkdir build && cd build
cmake -G Ninja \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DPYCLINGCON_ENABLE=OFF \
    -DCMAKE_CXX_FLAGS="-std=c++17" \
    -DCMAKE_INSTALL_LIBDIR=lib \
    ..
cmake --build . --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("clingcon", :clingcon),
    LibraryProduct("libclingcon",:libclingcon)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Clingo_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"8")
