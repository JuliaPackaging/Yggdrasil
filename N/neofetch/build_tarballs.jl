# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "neofetch"
version = v"7.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/dylanaraps/neofetch/archive/refs/tags/$(version).tar.gz",
                  "58a95e6b714e41efc804eca389a223309169b2def35e57fa934482a6b47c27e7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/neofetch-*/
export PREFIX=$prefix
make install
install_license LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = [
    FileProduct("bin/neofetch", :neofetch)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
