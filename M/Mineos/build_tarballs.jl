# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Mineos"
# Note, this project has not been updated since Nov 2014,
# we take the last commit and call it 1.0.2
# Last officially released version is 1.0.1
version = v"1.0.2" 

# Collection of sources required to build Mineos
sources = [
    GitSource("https://github.com/geodynamics/mineos.git", "3f33ba4400dd8c03dc5db1aec32dcc5eb85d5f80")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mineos

autoupdate
autoreconf --install
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
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

