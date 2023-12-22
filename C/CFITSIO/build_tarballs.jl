# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIO"
version = v"4.3.1"

# Collection of sources required to build CFITSIO
sources = [
    ArchiveSource("http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-$(version).tar.gz",
                  "47a7c8ee05687be1e1d8eeeb94fb88f060fbf3cd8a4df52ccb88d5eb0f5062be"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # See <https://github.com/JuliaPackaging/Yggdrasil/issues/7745>:
    # Remove the new fancy linkers which don't work yet
    rm /opt/bin/${bb_full_target}/ld64.lld
    rm /opt/bin/${bb_full_target}/ld64.${target}
    rm /opt/bin/${bb_full_target}/${target}-ld64.lld
    rm /opt/${MACHTYPE}/bin/ld64.lld
fi

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
