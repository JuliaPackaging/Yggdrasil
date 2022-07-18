# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Btop"
version = v"1.2.8"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/aristocratos/btop/archive/refs/tags/v$(version).tar.gz",
                  "7944b06e3181cc1080064adf1e9eb4f466af0b84a127df6697430736756a89ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/btop*/
# Don't do lto, doesn't seem to work on FreeBSD
make -j${nproc} OPTFLAGS="-O2 -ftree-loop-vectorize"
make install PREFIX=${prefix}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; exclude=Sys.iswindows); skip=Returns(false))

# The products that we will ensure are always built
products = [
    ExecutableProduct("btop", :btop)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.6", preferred_gcc_version=v"10")
