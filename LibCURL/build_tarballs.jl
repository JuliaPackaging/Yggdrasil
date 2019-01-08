# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.61.0"

# Collection of sources required to build LibCURL
sources = [
    "https://curl.haxx.se/download/curl-7.61.0.tar.gz" =>
    "64141f0db4945268a21b490d58806b97c615d3d0c75bf8c335bbe0efd13b45b5",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-7.61.0
./configure --prefix=$prefix --host=$target --with-mbedtls --disable-manual --without-ssl
make -j${nproc}
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcurl", :libcurl),
    ExecutableProduct(prefix, "curl", :curl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.1/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.16.0/build_MbedTLS.v2.13.1.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

