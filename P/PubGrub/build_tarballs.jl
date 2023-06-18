# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "PubGrub"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/pubgrub-rs/pubgrub/archive/refs/tags/v$(version).tar.gz",
                  "3b33133f2e567ebb14d4ff52ef780495847be6564cc6888066bee7679b36ef41"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pubgrub*/
cargo build --release
# install the products...
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust], julia_compat="1.6")
