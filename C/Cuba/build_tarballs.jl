# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

# Collection of sources required to build Cuba
name = "Cuba"
version = v"4.2.2"

sources = [
    GitSource("https://github.com/giordano/cuba.git",
              "3de82ee4d172c9a356539ff2755372d80729677f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cuba/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make shared
make install
rm "${prefix}/lib/libcuba.a" "${prefix}/share/cuba.pdf"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcuba", :libcuba),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
