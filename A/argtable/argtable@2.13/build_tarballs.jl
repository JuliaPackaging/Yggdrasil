# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

include("../common.jl")

version = v"2.13"

sources = [
    ArchiveSource(
        "https://downloads.sourceforge.net/project/argtable/argtable/argtable-2.13/argtable2-13.tar.gz",
        "8f77e8a7ced5301af6e22f47302fdbc3b1ff41f2b83c43c77ae5ca041771ddbf",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/argtable2-13
install_license COPYING
CC=gcc
CXX=g++
autoreconf -fvi
./configure --build=$MACHTYPE --host=$target --target=$target --prefix=$prefix
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# argtable 2.x does not support building DLLs via MinGW cross-compilation, consult the README!
platforms = supported_platforms(; exclude = Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

products = [LibraryProduct("libargtable2", :libargtable2)]

build_argtable(version, sources, script, platforms, products)
