# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build Cuba
name = "Cuba"
version = v"4.2a"
sources = [
    "https://github.com/giordano/cuba/archive/11bfbf509088f168622b8268f49c0a59ee81758b.tar.gz" =>
    "9cbb3a9c6ea541d7f3b0efcba6a865082e70536aded6a347bcec4873df3f3cc4",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cuba-*/
if [[ "${target}" == *-freebsd* ]]; then
    CC=/opt/${target}/bin/${target}-gcc
    LD=/opt/${target}/bin/${target}-ld
fi
./configure --prefix=${prefix} --host=${target}
make -j${nproc} shared
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcuba", :libcuba)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
