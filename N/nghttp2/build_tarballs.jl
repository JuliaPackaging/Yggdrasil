# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nghttp2"
version = v"1.40.0"

# Collection of sources required to build LibCURL
sources = [
    ArchiveSource("https://github.com/nghttp2/nghttp2/releases/download/v$(version)/nghttp2-$(version).tar.bz2",
                  "82758e13727945f2408d0612762e4655180b039f058d5ff40d055fa1497bd94f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nghttp2-*

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --enable-lib-only
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=[Windows(:i686),Windows(:x86_64)])

# The products that we will ensure are always built
products = [
    LibraryProduct("libnghttp2", :libnghttp2),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
