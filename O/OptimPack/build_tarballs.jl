# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "OptimPack"
version = v"3.2.0"

# Collection of sources required to build OptimPAck
sources = [
    ArchiveSource("https://github.com/emmt/OptimPack/releases/download/v$(version)/optimpack-$(version).tar.gz",
                  "3df032cde5ba6a3ffa04f0b0fd95d0694b75af82c8d2ddff0666c61e86c3ef5a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/optimpack-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-shared=yes --enable-static=no
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    # This is needed in order to build the shared library on Windows
    FLAGS+=(LDFLAGS="-no-undefined")
fi
make -j${nproc} "${FLAGS[@]}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopk",    :libopk),
    LibraryProduct("libcobyla", :libcobyla),
    LibraryProduct("libbobyqa", :libbobyqa),
    LibraryProduct("libnewuoa", :libnewuoa)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
