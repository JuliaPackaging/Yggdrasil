# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.26.1"

# Collection of sources required to build Git
sources_unix = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz",
    "888228408f254634330234df3cece734d190ef6381063821f31ec020538f0368")
]

sources_w32 = [
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2",
    "7c9bf2b200d1f65ae0d038c6801efa410760da880eb1f5e683ea8e1efd288c38")
]

sources_w64 = [
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2",
    "066c2e88c32d942e32d78aa888559b76ec1785e642b498c6710900026dc05310")
]

# Bash recipe for building across all Unices
script_unix = raw"""
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

# Bash recipe for installing on Windows
script_win = raw"""
cd $WORKSPACE/srcdir/mingw*/
cp -r * ${prefix}
"""

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

# Install first for win32, then win64.  This will accumulate files into `products` and also wrappers into the JLL package.
non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

include("../../fancy_toys.jl")

if should_build_platform("i686-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_w32, script_win, [Windows(:i686)], products, [])
end
if should_build_platform("x86_64-w64-mingw32")
    build_tarballs(non_reg_ARGS, name, version, sources_w64, script_win, [Windows(:x86_64)], products, [])
end
# Then for everything else.  This is the only one that we try to register, and this is the step that will open a PR against General
platforms = filter!(p -> !isa(p, Windows), supported_platforms())
# Get the non-Windows platforms that have been actually requested
filter!(p -> should_build_platform(triplet(p)), platforms)
if !isempty(platforms)
    build_tarballs(ARGS, name, version, sources_unix, script_unix, platforms, products, dependencies)
end
