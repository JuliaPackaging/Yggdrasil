using BinaryBuilder

name = "PCRE"
version = v"8.42"

# Collection of sources required to build Pcre
sources = [
    "https://ftp.pcre.org/pub/pcre/pcre-$(version.major).$(version.minor).tar.bz2" =>
    "2cd04b7c887808be030254e8d77de11d3fe9d4505c39d4b15d2664ffe8bf9301",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/pcre-*/

# On OSX, override choice of AR
if [[ ${target} == *apple-darwin* ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi
./configure --prefix=$prefix --host=$target --enable-utf8 --enable-unicode-properties
make -j${nproc} VERBOSE=1
make install VERBOSE=1
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

