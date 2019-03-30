using BinaryBuilder

name = "PCRE2"
version = v"10.31"

# Collection of sources required to build Pcre
sources = [
    "https://ftp.pcre.org/pub/pcre/pcre2-$(version.major).$(version.minor).tar.bz2" =>
    "e07d538704aa65e477b6a392b32ff9fc5edf75ab9a40ddfc876186c4ff4d68ac",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre2-*/

# On OSX, override choice of AR
if [[ ${target} == *apple-darwin* ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi

# Update configure scripts
update_configure_scripts

# Force optimization
export CFLAGS="${CFLAGS} -O3"

./configure --prefix=$prefix --host=$target --enable-utf8 --enable-unicode-properties --enable-jit
make -j${nproc} V=1
make install V=1

# On windows we need libcpre2-8.dll as well
if [[ ${target} == *mingw* ]]; then
    cp ${prefix}/bin/libpcre2-8-0.dll ${prefix}/bin/libpcre2-8.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libpcre", :libpcre)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

