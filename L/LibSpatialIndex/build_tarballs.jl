using BinaryBuilder

name = "LibSpatialIndex"
version = v"1.8.5"

# Collection of sources required to build LibSpatialIndex
sources = [
    ArchiveSource("http://download.osgeo.org/libspatialindex/spatialindex-src-1.8.5.tar.bz2",
        "31ec0a9305c3bd6b4ad60a5261cba5402366dd7d1969a8846099717778e9a50a"),
    DirectorySource("./patches"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd spatialindex-src-*

patch < ${WORKSPACE}/srcdir/makefile.patch
rm Makefile.am.orig

if [ $target = "x86_64-w64-mingw32" ] || [ $target = "i686-w64-mingw32" ]; then
  patch < ${WORKSPACE}/srcdir/header-check.patch
fi

aclocal
autoconf
automake --add-missing --foreign

# Show options in the log
./configure --help

./configure --prefix=${prefix} --host=$target --build=${MACHTYPE} --enable-static=no
make
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libspatialindex_c", :libspatialindex_c),
    LibraryProduct("libspatialindex", :libspatialindex),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
