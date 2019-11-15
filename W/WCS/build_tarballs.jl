using BinaryBuilder

name = "WCS"
version = v"6.4.0"

# Collection of sources required to build WCS
sources = [
    "https://cache.julialang.org/ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-$(version.major).$(version.minor).tar.bz2" =>
    "13c11ff70a7725563ec5fa52707a9965fce186a1766db193d08c9766ea107000",
    "./patches"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wcslib-*/
if [[ "${target}" == *mingw* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/configure-mingw.patch"
    autoconf
    export CFLAGS="${CFLAGS} -DNO_OLDNAMES"
fi
./configure --prefix=$prefix --host=$target --disable-fortran --without-cfitsio --without-pgplot --disable-utils
make -j${nproc}
make install

# Install all license files
install_license COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libwcs", :libwcs),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
