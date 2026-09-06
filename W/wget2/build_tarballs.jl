# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wget2"
version = v"2.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/wget/wget2-$(version).tar.gz",
                  "d7544b13e37f18e601244fce5f5f40688ac1d6ab9541e0fbb01a32ee1fb447b4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wget2*

if [[ ${target} == x86_64-linux-musl ]]; then
    # Avoid finding the host Brotli libraries
    rm /usr/lib/libbrotli*
fi

if [[ ${target} == *-w64-mingw32 ]]; then
    # There is no pkgconfig info for OpenSSL on Windows
    export OPENSSL_CFLAGS="-I${includedir}"
    export OPENSSL_LIBS="-L${libdir} -lssl"
fi

./configure \
    --host=${target} \
    --build=${MACHTYPE} \
    --prefix=${prefix} \
    --disable-doc \
    --disable-manylibs \
    --enable-shared=yes \
    --enable-static=no \
    --with-brotlidec \
    --with-bzip2 \
    --with-libidn2 \
    --with-libpcre2 \
    --with-libpsl \
    --with-lzma \
    --with-ssl=openssl \
    --with-zlib \
    $(if [[ ${target} == *-w64-mingw32 ]]; then echo ' --without-zstd'; else echo ' --with-zstd'; fi) \
    --without-gpgme  \
    --without-libhsts \
    --without-libidn \
    --without-libmicrohttpd \
    --without-libnghttp2 \
    --without-libpcre \
    --without-lzip \
    --without-plugin-support

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("wget2", :wget2),
    #ExecutableProduct("wget2_noinstall", :wget2_noinstall),
    LibraryProduct("libwget", :libwget)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.9"),
    Dependency("Gettext_jll"; compat="=0.21.0"),
    Dependency("OpenSSL_jll"; compat="3.0.16"),
    Dependency("PCRE2_jll"; compat="10.42.0"),
    Dependency("XZ_jll"; compat="5.8.2"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("brotli_jll"; compat="1.2.0"),
    Dependency("libidn2_jll"; compat="2.3.7"),
    Dependency("libpsl_jll"; compat="0.21.5"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
