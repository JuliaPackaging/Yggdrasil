# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build Cuba
name = "Cuba"
version = v"4.2"
sources = [
    GitSource("https://github.com/giordano/cuba.git",
              "9ec75f3ce2b881d5a34713462cf1cee9be1f90df"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cuba/

./configure --prefix=${prefix} --host=${target}
make -j${nproc} shared
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcuba", :libcuba)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
