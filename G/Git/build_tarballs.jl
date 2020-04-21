# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.26.1"

# Collection of sources required to build Git
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz",
                  "888228408f254634330234df3cece734d190ef6381063821f31ec020538f0368"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2",
                  "7c9bf2b200d1f65ae0d038c6801efa410760da880eb1f5e683ea8e1efd288c38"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2",
                  "066c2e88c32d942e32d78aa888559b76ec1785e642b498c6710900026dc05310"; unpack_target = "x86_64-w64-mingw32"),
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
