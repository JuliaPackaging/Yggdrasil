# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"3.49.1" # <--- This version number is a lie to build for experimental platforms

# Collection of sources required to build CFITSIO
sources = [
    ArchiveSource("http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version.major).$(version.minor).tar.gz",
                  "5b65a20d5c53494ec8f638267fca4a629836b7ac8dd0ef0266834eab270ed4b3"),
    DirectorySource("./bundled"),
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
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-reentrant
make -j${nproc} shared
make install
# Delete the static library
rm ${prefix}/lib/libcfitsio.a
# On Windows platforms, we need to move our .dll files to bin
if [[ "${target}" == *-mingw* ]]; then
    mkdir -p ${libdir}
    mv ${prefix}/lib/*.dll ${libdir}/.
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcfitsio", :libcfitsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
