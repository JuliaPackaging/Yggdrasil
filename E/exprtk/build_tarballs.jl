# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "exprtk"
version = v"0.0.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ArashPartow/exprtk", "a4b17d543f072d2e3ba564e4bc5c3a0d2b05c338"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/exprtk

install -Dvm 644 exprtk.hpp ${includedir}/exprtk.hpp

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
