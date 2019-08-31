# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

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

CPPFLAGS="-I${prefix}/include"

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
products(prefix) = Product[
    LibraryProduct(prefix, "libfontconfig", :libfontconfig)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaGraphics/FreeTypeBuilder/releases/download/v2.9.1-4/build_FreeType2.v2.10.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Bzip2-v1.0.6-2/build_Bzip2.v1.0.6.jl",
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/giordano/Yggdrasil/releases/download/Libuuid-v2.34/build_Libuuid.v2.34.0.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Expat-v2.2.7%2B0/build_Expat.v2.2.7.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
