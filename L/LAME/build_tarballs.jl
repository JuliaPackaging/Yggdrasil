# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "LAME"
version_string = "3.100"
version = v"3.100.3"

# Collection of sources required to build liblame
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/lame/lame/$(version_string)/lame-$(version_string).tar.gz",
                  "ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/lame-*
sed -i '2d' include/libmp3lame.sym
apk add nasm
if [[ $(uname -m) == i?86 ]]; then
    sed -i -e 's/<xmmintrin.h/&.nouse/' configure
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("lame", :lame),
    LibraryProduct("libmp3lame", :libmp3lame),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
