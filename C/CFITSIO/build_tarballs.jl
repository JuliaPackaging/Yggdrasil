# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"4.4.0"

# Collection of sources required to build CFITSIO
sources = [
    ArchiveSource("http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version).tar.gz",
                  "95900cf95ae760839e7cb9678a7b2fad0858d6ac12234f934bd1cb6bfc246ba9"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cfitsio*
atomic_patch -p1 ../patches/configure_in.patch
atomic_patch -p1 ../patches/Makefile_in.patch
if [[ $target == *-freebsd* ]]; then
   # `gethostbyname` is considered outdated and not available any more; declare it manually
   atomic_patch -p1 ../patches/gethostbyname.patch
fi
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
    Dependency("LibCURL_jll"; compat="7.73,8"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               # When using lld for AArch64 macOS, linking fails with
               #     ld64.lld: error: -dylib_current_version 10.4.3.1: malformed version
               julia_compat="1.6", clang_use_lld=false)

# Build trigger: 1
