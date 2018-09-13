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
if [[ $target == *-w64-mingw32 ]]; then
    LDFLAGS="-L$prefix/bin"
elif [[ $target == x86_64-apple-darwin14 ]]; then
    LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib"
else
    LDFLAGS="-L$prefix/lib -Wl,-rpath-link,$prefix/lib"
fi
make -j${nproc} LDFLAGS="$LDFLAGS"
make install

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, :glibc),
    Linux(:x86_64, :glibc),
    Linux(:aarch64, :glibc),
    Linux(:armv7l, :glibc, :eabihf),
    Linux(:powerpc64le, :glibc),
    Linux(:i686, :musl),
    Linux(:x86_64, :musl),
    Linux(:aarch64, :musl),
    Linux(:armv7l, :musl, :eabihf),
    MacOS(:x86_64),
    FreeBSD(:x86_64),
    Windows(:i686),
    Windows(:x86_64),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcurl", :libcurl),
    ExecutableProduct(prefix, "curl", :curl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.1/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.11/build_MbedTLS.v1.0.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

