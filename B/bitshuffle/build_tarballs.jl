# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bitshuffle"
version = v"0.4.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiyo-masui/bitshuffle.git", "a60471d37a8cbbd8265dc8cfa83a9320abdcb590")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd bitshuffle/src
$CC -O3 -std=c99 -fPIC --shared -o bitshuffle.${dlext} iochain.c bitshuffle_core.c
install -D -t ${libdir} bitshuffle.${dlext}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("bitshuffle", :bitshuffle_lib)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
