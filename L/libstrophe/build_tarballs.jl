# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libstrophe"
version = v"0.14.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/strophe/libstrophe.git", "b852c3e957b408cf857e920c8b3d854c6004a721"),
]

# Script template (structure is the same for all platforms, directory for make differs)
script = raw"""
cd $WORKSPACE/srcdir/libstrophe
./bootstrap.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --disable-examples
make -j${nproc}
make install
"""

platforms = supported_platforms(; exclude=Sys.iswindows)

products = [
    LibraryProduct("libstrophe", :libstrophe)
]

dependencies = [
    Dependency("Expat_jll")
    Dependency("OpenSSL_jll"; compat="3.0.16")
    Dependency("Zlib_jll")
]


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
