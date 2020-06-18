# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.27.0"

# Collection of sources required to build Git
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz",
                  "73ca9774d7fa226e1d87c1909401623f96dca6a044e583b9a762e84d7d1a73f9"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2",
                  "96bcfb93c7fbb34bbd4c5c9ba14a2a6ae8f58b299688278e38db1dacad180df2"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2",
                  "a653c41999e4c80eebde8de046dd92a5a9e38a77f60466120daab2f31d3d0935"; unpack_target = "x86_64-w64-mingw32"),
]

# Bash recipe for building across all platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/git-*/COPYING

if [[ "${target}" == *-ming* ]]; then
    # Fast path for Windows: just copy the content of the tarball to the prefix
    cp -r ${WORKSPACE}/srcdir/${target}/mingw${nbits}/* ${prefix}
    exit
fi

cd $WORKSPACE/srcdir/git-*/

# We need a native "msgfmt" to cross-compile
apk add tcl gettext

# Git doesn't want to be cross-compiled, but we swear that we're not going to
# cross-compile
sed -i 's/cross_compiling=yes/cross_compiling=no/' configure

if [[ "${target}" == *-apple-* ]]; then
    LDFLAGS="-lgettextlib"
elif [[ ${target} == *-freebsd* ]]; then
    LDFLAGS="-L${prefix}/lib -lcharset"
fi

./configure --prefix=$prefix --host=$target \
    --with-curl \
    --with-expat \
    --with-openssl \
    --with-iconv=${prefix} \
    --with-libpcre2 \
    --with-zlib=${prefix} \
    CPPFLAGS="-I${prefix}/include" \
    LDFLAGS="${LDFLAGS}"
make -j${nproc}
make install INSTALL_SYMLINKS="yes, please"
"""

platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("git", :git),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibCURL_jll"),
    Dependency("Expat_jll"),
    Dependency("OpenSSL_jll"),
    Dependency("Gettext_jll"),
    Dependency("Libiconv_jll"),
    Dependency("PCRE2_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
