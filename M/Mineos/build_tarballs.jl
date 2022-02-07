# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Mineos"
version = v"1.0"

# Collection of sources required to build Mineos
sources = [
    GitSource("https://github.com/anowacki/mineos.git", "f8e1c1dc4bf5aa62d5da98648424ad2611ff7cd3")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mineos
autoreconf --install
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-doc
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("simpledit", :simpledit),
    ExecutableProduct("endi", :endi),
    ExecutableProduct("eigcon", :eigcon),
    ExecutableProduct("eigen2asc", :eigen2asc),
    ExecutableProduct("green", :green),
    ExecutableProduct("syndat", :syndat),
    ExecutableProduct("minos_bran", :minos_bran),
    ExecutableProduct("cucss2sac", :cucss2sac)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")

