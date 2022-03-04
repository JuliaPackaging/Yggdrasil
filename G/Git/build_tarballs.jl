# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Git"
version = v"2.34.1"

# Collection of sources required to build Git
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/software/scm/git/git-$(version).tar.xz",
                  "3a0755dd1cfab71a24dd96df3498c29cd0acd13b04f3d08bf933e81286db802c"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-32-bit.tar.bz2",
                  "109d69b92e5383d40765064bcd25183af05b12c64a95597419a703004a7c8521"; unpack_target = "i686-w64-mingw32"),
    ArchiveSource("https://github.com/git-for-windows/git/releases/download/v$(version).windows.1/Git-$(version)-64-bit.tar.bz2",
                  "0d962f5894b94b93a966a2c12f77330e5f68aacae775059fb30dd61f2c08ef00"; unpack_target = "x86_64-w64-mingw32"),
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

# We need a native "tclsh" to cross-compile
apk add tcl

CACHE_VALUES=()
if [[ "${target}" != *86*-linux-* ]]; then
    # Cache values of some tests, let's hope to have got them right
    CACHE_VALUES+=(
        ac_cv_iconv_omits_bom=no
        ac_cv_fread_reads_directories=yes
        ac_cv_snprintf_returns_bogus=no
    )
else
    # Explain Git that we aren't cross-compiling on these platforms
    sed -i 's/cross_compiling=yes/cross_compiling=no/' configure
fi

if [[ "${target}" == *-apple-* ]]; then
    LDFLAGS="-lgettextlib"
elif [[ ${target} == *-freebsd* ]]; then
    LDFLAGS="-L${prefix}/lib -lcharset"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-curl \
    --with-expat \
    --with-openssl \
    --with-iconv=${prefix} \
    --with-libpcre2 \
    --with-zlib=${prefix} \
    "${CACHE_VALUES[@]}" \
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
    # Need a host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    Dependency("LibCURL_jll"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    # I believe Gettext is needed for macOS (and probably only here)
    Dependency("Gettext_jll"; compat="=0.21.0"),
    Dependency("Libiconv_jll"),
    Dependency("PCRE2_jll", v"10.35.0"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
