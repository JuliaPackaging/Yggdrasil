# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Fontconfig"
version = v"2.13.1"

# Collection of sources required to build FriBidi
sources = [
    "https://www.freedesktop.org/software/fontconfig/release/fontconfig-$(version).tar.bz2" =>
    "f655dd2a986d7aa97e052261b36aa67b0a64989496361eca8d604e6414006741",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fontconfig-*/

apk add gperf

# Ensure that `${prefix}/include` is..... included
export CPPFLAGS="-I${prefix}/include"

atomic_patch -p1 ../patches/configure_freetype2_version.patch
autoreconf
./configure --prefix=$prefix --host=$target --disable-docs

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !(p isa Windows)]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libfontconfig", :libfontconfig)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "FreeType2_jll",
    "Bzip2_jll",
    "Zlib_jll",
    "Libuuid_jll",
    "Expat_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
