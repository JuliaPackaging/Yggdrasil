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
cd $WORKSPACE/srcdir/hand-isomorphism/src/
install_license ../LICENSE.txt
install -Dvm 644 hand_index.h ${includedir}/hand_index.h
mkdir -p "${libdir}"
cc -std=c99 -O2 -shared -o "${libdir}/libhandisomorphism.${dlext}" -fPIC deck.c hand_index.c -lm
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhandisomorphism", :libhandisomorphism)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
