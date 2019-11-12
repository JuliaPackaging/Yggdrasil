# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Opus"
version = v"1.3.1"

# Collection of sources required to build Opus
sources = [
    "https://archive.mozilla.org/pub/opus/opus-$(version).tar.gz" =>
    "65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/opus-*/

# On musl, disable stack protection (https://www.openwall.com/lists/musl/2018/09/11/2)
if [[ ${target} == *musl* ]]; then
    STACK_PROTECTOR="--disable-stack-protector"
fi

./configure --prefix=$prefix --host=$target --disable-static --enable-custom-modes ${STACK_PROTECTOR}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libopus", :libopus),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
