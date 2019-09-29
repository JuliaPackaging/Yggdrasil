# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libepoxy"
version = v"1.5.3"

# Collection of sources required to build Libepoxy
sources = [
    "https://github.com/anholt/libepoxy/releases/download/$(version)/libepoxy-$(version).tar.xz" =>
    "002958c5528321edd53440235d3c44e71b5b1e09b9177e8daf677450b6c4433d"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libepoxy-*/
mkdir build && cd build

# build doesn't find libx11 properly; add certain cflags into meson invocation
sed -i "s&c_args = \[\]&c_args = \['-I${prefix}/include'\]&g" "${MESON_TARGET_TOOLCHAIN}"

# Next, build
meson .. -Dtest=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libepoxy", :libepoxy),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libglvnd_jll",
    "X11_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
