# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "nghttp2"
version = v"1.41.0"

# Collection of sources required to build LibCURL
sources = [
    ArchiveSource("https://github.com/nghttp2/nghttp2/releases/download/v$(version)/nghttp2-$(version).tar.xz",
                  "abc25b8dc601f5b3fefe084ce50fcbdc63e3385621bee0cbfa7b57f9ec3e67c2"),
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
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnghttp2", :libnghttp2),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

