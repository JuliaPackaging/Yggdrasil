# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libfdk_aac"
version = v"0.1.6"

# Collection of sources required to build libfdk
sources = [
    "https://downloads.sourceforge.net/opencore-amr/fdk-aac-$(version).tar.gz" =>
    "aab61b42ac6b5953e94924c73c194f08a86172d63d39c5717f526ca016bed3ad",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fdk-aac-*
./configure --prefix=$prefix --host=$target
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libfdk-aac", :libfdk)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
