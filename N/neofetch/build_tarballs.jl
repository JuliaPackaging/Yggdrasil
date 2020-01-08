# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "neofetch"
version = v"6.1.0"

# Collection of sources required to complete build
sources = [
    "https://github.com/dylanaraps/neofetch/archive/6.1.0.tar.gz" =>
    "ece351e35286b64d362000d409b27597fcbdcf77e8e60fa0adae1f29d3c29637",
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    FileProduct("bin/neofetch", :neofetch)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
