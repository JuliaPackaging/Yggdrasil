# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OptimPack"
version = v"3.1.0"

# Collection of sources required to build OptimPAck
sources = [
    "https://github.com/emmt/OptimPack/releases/download/v$(version)/optimpack-$(version).tar.gz" =>
        "fa1efdbebf6efa42a1d6b4f6223c7ca0b871fad5c0b53f7dc9be296e4c766190",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/optimpack-*
./configure --prefix=$prefix --host=$target --enable-shared=yes --enable-static=no
make -j${nproc}
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
products(prefix) = [
    LibraryProduct(prefix, "libopk",    :libopk),
    LibraryProduct(prefix, "libcobyla", :libcobyla),
    LibraryProduct(prefix, "libbobyqa", :libbobyqa),
    LibraryProduct(prefix, "libnewuoa", :libnewuoa)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
