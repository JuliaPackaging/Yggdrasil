# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "liblame"
version = v"3.100.0"

# Collection of sources required to build liblame
sources = [
    "https://downloads.sourceforge.net/lame/lame-3.100.tar.gz" =>
    "ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e",

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd lame-3.100/
sed -i '2d' include/libmp3lame.sym
apk add nasm
case $(uname -m) in    i?86) sed -i -e 's/<xmmintrin.h/&.nouse/' configure ;; esac
./configure --prefix=$prefix --host=$target
make -j${ncore}
make install
exit

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmp3lame", :libmp3lame)
]

# Dependencies that must be installed before this package can be built
dependencies = [

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
