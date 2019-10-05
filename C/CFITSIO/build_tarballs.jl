# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"3.47.0"

# Collection of sources required to build CFITSIO
sources = [
    "http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version.major).$(version.minor).tar.gz" =>
    "418516f10ee1e0f1b520926eeca6b77ce639bed88804c7c545e74f26b3edf4ef",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cfitsio*
atomic_patch -p1 ../patches/configure_in.patch
atomic_patch -p1 ../patches/Makefile_in.patch
autoreconf
if [[ "${target}" == *-mingw* ]]; then
    # This is ridiculous: when CURL is enabled, CFITSIO defines a macro,
    # `TBYTE`, that has the same name as a mingw macro.  The following patch
    # renames `TBYTE` to `_TBYTE`.
    atomic_patch -p1 ../patches/tbyte.patch
fi
./configure --prefix=$prefix --host=$target --enable-reentrant
make -j${nproc} shared
make install
# On Windows platforms, we need to move our .dll files to bin
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p ${prefix}/bin
    mv ${prefix}/lib/*.dll ${prefix}/bin
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcfitsio", :libcfitsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "LibCURL_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
