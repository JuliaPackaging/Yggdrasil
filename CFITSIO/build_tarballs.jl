# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CFITSIOBuilder"
version = v"3.47.0"

# Collection of sources required to build CFITSIO
sources = [
    "http://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-3.47.tar.gz" =>
    "418516f10ee1e0f1b520926eeca6b77ce639bed88804c7c545e74f26b3edf4ef",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cfitsio*
if [[ "${target}" == *freebsd* ]]; then
    CC=/opt/${target}/bin/${target}-gcc
    LD=/opt/${target}/bin/${target}-ld
fi
./configure --prefix=$prefix --host=$target --enable-reentrant
make -j${nproc} shared
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libcfitsio", :libcfitsio)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
