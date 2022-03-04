# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"4.0.0"

# Collection of sources required to build CFITSIO
sources = [
    ArchiveSource("http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version).tar.gz",
                  "b2a8efba0b9f86d3e1bd619f662a476ec18112b4f27cc441cc680a4e3777425e"),
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
    # `TBYTE`, that has the same name as a mingw macro.  Let's rename all
    # `TBYTE` to `_TBYTE`.
    sed -i 's/\<TBYTE\>/_TBYTE/g' $(grep -lr '\<TBYTE\>')
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcfitsio", :libcfitsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("LibCURL_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
