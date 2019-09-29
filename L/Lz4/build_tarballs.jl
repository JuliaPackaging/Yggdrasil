# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Lz4"
version = v"1.9.2"

# Collection of sources required to build Lz4
sources = [
    "https://github.com/lz4/lz4/archive/v$(version).tar.gz" =>
    "658ba6191fa44c92280d4aa2c271b0f4fbc0e34d249578dd05e50e76d0e5efcc",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lz4-*/
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["liblz4", "msys-lz4"], :liblz4),
    ExecutableProduct("lz4", :lz4),
    ExecutableProduct("lz4c", :lz4c),
    ExecutableProduct("lz4cat", :lz4cat),
    ExecutableProduct("unlz4", :unlz4),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
