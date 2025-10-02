# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LibCURL"
version = v"7.73.0"

# Collection of sources required to build LibCURL
sources = [
    ArchiveSource("https://curl.haxx.se/download/curl-$(version).tar.gz",
                  "ba98332752257b47b9dea6d8c0ad25ec1745c20424f1dd3ff2c99ab59e97cf91"),
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

    # A few things we actually enable
    --with-libssh2=${prefix} --with-zlib=${prefix} --with-nghttp2=${prefix}
    --disable-versioned-symbols
)


if [[ ${target} == *mingw* ]]; then
    # We need to tell it where to find libssh2 on windows
    FLAGS+=(LDFLAGS="${LDFLAGS} -L${prefix}/bin")

    # We also need to tell it to link against schannel (native TLS library)
    FLAGS+=(--with-schannel)
elif [[ ${target} == *darwin* ]]; then
    # On Darwin, we need to use SecureTransport (native TLS library)
    FLAGS+=(--with-secure-transport)

    # We need to explicitly request a higher `-mmacosx-version-min` here, so that it doesn't
    # complain about: `Symbol not found: ___isOSVersionAtLeast`
    if [[ "${target}" == aarch64* ]]; then
        export CFLAGS=-mmacosx-version-min=11.0
    else
        export CFLAGS=-mmacosx-version-min=10.11
    fi
else
    # On all other systems, we use MbedTLS
    FLAGS+=(--with-mbedtls=${prefix})
fi

atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-socks-return-error-if-hostname-too-long-for-remote-r.patch || true

./configure --prefix=$prefix --host=$target --build=${MACHTYPE} "${FLAGS[@]}"
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcurl", :libcurl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibSSH2_jll"; compat="1.9.1"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("nghttp2_jll"; compat="1.41.0"),
    # Note that while we unconditionally list MbedTLS as a dependency,
    # we default to schannel/SecureTransport on Windows/MacOS.
    Dependency("MbedTLS_jll"; compat="2.24.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 2
