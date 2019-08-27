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
cd $WORKSPACE/srcdir/curl-*

# Holy crow we really configure the bitlets out of this thing
FLAGS=(
    # Disable....almost everything
    --without-ssl --without-gnutls --without-gssapi --without-zlib
    --without-libidn --without-libidn2 --without-libmetalink --without-librtmp
    --without-nghttp2 --without-nss --without-polarssl
    --without-spnego --without-libpsl --disable-ares --disable-manual
    --disable-ldap --disable-ldaps --without-zsh-functions-dir

    # Two things we actually enable
    --with-libssh2=${prefix} --with-mbedtls=${prefix}
)

# We need to tell it where to find libssh2 on windows
if [[ ${target} == *mingw* ]]; then
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")
fi

./configure --prefix=$prefix --host=$target "${FLAGS[@]}"
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
    "https://github.com/JuliaWeb/MbedTLSBuilder/releases/download/v0.16.0/build_MbedTLS.v2.13.1.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/LibSSH2-v1.9.0+0/build_LibSSH2.v1.9.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

