# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.23.0"

# Collection of sources required to build Git
sources = [
    "https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz" =>
    "234fa05b6839e92dc300b2dd78c92ec9c0c8d439f65e1d430a7034f60af16067"
]

# Bash recipe for building across all platforms
script = raw"""
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("git", :git),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "LibCURL_jll",
    "Expat_jll",
    "OpenSSL_jll",
    "Gettext_jll",
    "Libiconv_jll",
    "PCRE2_jll",
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
