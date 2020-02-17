# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libepoxy"
version = v"1.5.4"

# Collection of sources required to build Libepoxy
sources = [
    ArchiveSource("https://github.com/anholt/libepoxy/releases/download/$(version)/libepoxy-$(version).tar.xz",
                  "0bd2cc681dfeffdef739cb29913f8c3caa47a88a451fd2bc6e606c02997289d2")
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
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
