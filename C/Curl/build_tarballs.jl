# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Curl"
version = v"7.66.0"

# Collection of sources required to build Curl
sources = [
    "https://curl.haxx.se/download/curl-$(version).tar.bz2" =>
    "6618234e0235c420a21f4cb4c2dd0badde76e6139668739085a70c4e2fe7a141"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-*/
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcurl", :libcurl),
    ExecutableProduct("curl", :curl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
