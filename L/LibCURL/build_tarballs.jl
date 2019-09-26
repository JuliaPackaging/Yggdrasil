# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.66.0"

# Collection of sources required to build LibCURL
sources = [
    "https://curl.haxx.se/download/curl-$(version).tar.bz2" =>
    "6618234e0235c420a21f4cb4c2dd0badde76e6139668739085a70c4e2fe7a141",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-*

# Holy crow we really configure the bitlets out of this thing
FLAGS=(
    # Disable....almost everything
    --without-ssl --without-gnutls --without-gssapi
    --without-libidn --without-libidn2 --without-libmetalink --without-librtmp
    --without-nghttp2 --without-nss --without-polarssl
    --without-spnego --without-libpsl --disable-ares --disable-manual
    --disable-ldap --disable-ldaps --without-zsh-functions-dir
    --disable-static

    # Two things we actually enable
    --with-libssh2=${prefix} --with-mbedtls=${prefix} --with-zlib=${prefix}
)

# We need to tell it where to find libssh2 on windows
if [[ ${target} == *mingw* ]]; then
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")
fi

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcurl", :libcurl),
    ExecutableProduct("curl", :curl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "LibSSH2_jll",
    "MbedTLS_jll",
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
