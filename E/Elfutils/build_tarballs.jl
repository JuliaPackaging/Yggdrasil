# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Elfutils"
version = v"0.177"

# Collection of sources required to build Elfutils
sources = [
    "https://sourceware.org/elfutils/ftp/$(version.major).$(version.minor)/elfutils-$(version.major).$(version.minor).tar.bz2" =>
    "fa489deccbcae7d8c920f60d85906124c1989c591196d90e0fd668e3dc05042e",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/elfutils-*/
./configure --prefix=${prefix} --host=${target}
make -j${nproc} CPPFLAGS="-I${prefix}/include" CFLAGS="-Wno-error=unused-result"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

# The products that we will ensure are always built
products = [
    LibraryProduct("libasm", :libasm),
    LibraryProduct("libdw", :libdw),
    LibraryProduct("libelf", :libelf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
    "Bzip2_jll",
    "XZ_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
