# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PRIMA"
version = v"0.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libprima/prima.git", "7565f6f42358062e56734a91fc62e0aa66ab7575")
]

# Bash recipe for building across all platforms
script = raw"""
cd prima
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libprimac", :libprimac),
    LibraryProduct("libprimaf", :libprimaf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
