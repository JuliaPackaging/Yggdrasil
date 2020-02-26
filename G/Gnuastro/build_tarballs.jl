# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Gnuastro"
version = v"0.11"

# Collection of sources required to build gnuastro
sources = [
    ArchiveSource("http://ftp.gnu.org/gnu/gnuastro/gnuastro-$(version.major).$(version.minor).tar.gz",
                  "f51a5fe6c2ac7218442aa87be883dbd98d130b48d5e2dff3abb2730113c76c2f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gnuastro-*/

if [[ "${target}" == i686-linux-musl ]]; then
    # Small hack: swear that we're cross-compiling.  Our `i686-linux-musl` is
    # bugged and it can run only a few programs, with the result that the
    # configure test to check whether we're cross-compiling returns that we're
    # doing a native build, but then it fails to run a bunch of programs during
    # other tests.
    sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
fi

if [[ "${target}" == *-mingw* ]]; then
    # Windows, here we go.  First off, need to patch configure to link
    # libcfitsio in the right order: first libcfitsio, then its dependencies.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/configure_libcfitsio_libs.patch"

    # Second, WCSLIB defines a function called `wcsset`, just like a Windows
    # function defined in <string.h>.  The following patch guards all inclusions
    # of <string.h>
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/wcsset.patch"

    # Also, CFITSIO aptly defines a macro called `TBYTE`, which is the same
    # name as a MinGW macro, so we are going to rename it here as we did for
    # CFITSIO.
    export CFLAGS="-DTBYTE=_TBYTE"
fi

export CPPFLAGS="-I${prefix}/include"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.  We are manually disabling
# many platforms that do not seem to work.
platforms = filter!(p -> !isa(p, Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgnuastro", :libgnuastro),
    ExecutableProduct("astarithmetic", :astarithmetic),
    ExecutableProduct("astconvertt", :astconvertt),
    ExecutableProduct("astconvolve", :astconvolve),
    ExecutableProduct("astcosmiccal", :astcosmiccal),
    ExecutableProduct("astcrop", :astcrop),
    ExecutableProduct("astfits", :astfits),
    ExecutableProduct("astmatch", :astmatch),
    ExecutableProduct("astmkcatalog", :astmkcatalog),
    ExecutableProduct("astmknoise", :astmknoise),
    ExecutableProduct("astmkprof", :astmkprof),
    ExecutableProduct("astnoisechisel", :astnoisechisel),
    ExecutableProduct("astscript-sort-by-night", :astscript_sort_by_night),
    ExecutableProduct("astsegment", :astsegment),
    ExecutableProduct("aststatistics", :aststatistics),
    ExecutableProduct("asttable", :asttable),
    ExecutableProduct("astwarp", :astwarp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CFITSIO_jll"),
    Dependency("GSL_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("Libtiff_jll"),
    Dependency("LibGit2_jll"),
    Dependency("WCS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
