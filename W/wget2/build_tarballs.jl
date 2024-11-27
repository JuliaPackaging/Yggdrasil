# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wget2"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/wget/wget2-$(version).tar.gz",
                  "2b3b9c85b7fb26d33ca5f41f1f8daca71838d869a19b406063aa5c655294d357")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wget2*

./configure \
    --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --prefix=${prefix} \
    --includedir=${includedir} \
    --libdir=${libdir} \
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
    --with-zstd \
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
#TODO # Nettle and OpenSSL needed for mingw builds
dependencies = [
    # Dependency("Nettle_jll"; compat="~3.7.2"),
    # Dependency(PackageSpec(name="GnuTLS_jll", uuid="0951126a-58fd-58f1-b5b3-b08c7c4a876d")),
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("Gettext_jll"; compat="=0.21.0"),
    Dependency("OpenSSL_jll"; compat="3.0.15"),
    Dependency("PCRE2_jll"),
    Dependency("XZ_jll"; compat="5.6.3"),
    Dependency("Zstd_jll"; compat="1.5.6"),
    Dependency("brotli_jll"; compat="1.1.0"),
    Dependency("libidn2_jll"; compat="2.3.7"),
    Dependency("libpsl_jll"; compat="0.21.5"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
