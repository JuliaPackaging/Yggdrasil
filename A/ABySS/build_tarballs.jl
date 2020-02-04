# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ABySS"
version = v"2.2.4"

# Collection of sources required to build ThinASLBuilder
sources = [
    "https://github.com/bcgsc/abyss.git" =>
    "ffd5e372b94b26d1e302271c5fb8f92b85381f0a"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/abyss/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-boost=${prefix}/include
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "boost_jll",
    "OpenMPI_jll"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)