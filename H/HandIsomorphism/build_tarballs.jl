# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HandIsomorphism"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kdub0/hand-isomorphism.git", "dabcee4a84c1d62ee6ded9b6ff02ece6823fcc0f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd hand-isomorphism/
cd src/
gcc -std=c99 -O2 -shared -o $prefix/libhandisomorphism.so -fPIC deck.c hand_index.c
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhandisomorphism", :handisomorphism)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"13.2.0")
