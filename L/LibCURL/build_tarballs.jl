# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.70.0"
cacert_version = "2020-01-01"

# Collection of sources required to build LibCURL
sources = [
    ArchiveSource("https://curl.haxx.se/download/curl-$(version).tar.gz", 
    "ca2feeb8ef13368ce5d5e5849a5fd5e2dd4755fecf7d8f0cc94000a4206fb8e7"), 
    FileSource("https://curl.haxx.se/ca/cacert-$cacert_version.pem", 
    "adf770dfd574a0d6026bfaa270cb6879b063957177a991d453ff1d302c02081f",
    filename="cacert.pem")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/curl-*

# Holy crow we really configure the bitlets out of this thing
FLAGS=(
    # Disable....almost everything
    --without-ssl --without-gnutls --without-gssapi
    --without-libidn --without-libidn2 --without-libmetalink --without-librtmp
    --without-nss --without-polarssl
    --without-spnego --without-libpsl --disable-ares --disable-manual
    --disable-ldap --disable-ldaps --without-zsh-functions-dir
    --disable-static

    # Two things we actually enable
    --with-libssh2=${prefix} --with-mbedtls=${prefix} --with-zlib=${prefix}
    --with-nghttp2=${prefix}
)

# We need to tell it where to find libssh2 on windows
if [[ ${target} == *mingw* ]]; then
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")
fi

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} "${FLAGS[@]}"
make -j${nproc}
make install
install_license COPYING
cp ../cacert.pem $prefix/share/cacert.pem
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcurl", :libcurl),
    ExecutableProduct("curl", :curl),
    FileProduct("share/cacert.pem", :cacert)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibSSH2_jll"),
    Dependency("MbedTLS_jll"),
    Dependency("Zlib_jll"),
    Dependency("nghttp2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

