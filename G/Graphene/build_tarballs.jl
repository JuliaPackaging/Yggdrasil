# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Graphene"
version = v"1.10.0"

# Collection of sources required to build Graphene
sources = [
    "https://github.com/ebassi/graphene/releases/download/$(version)/graphene-$(version).tar.xz" =>
    "406d97f51dd4ca61e91f84666a00c3e976d3e667cd248b76d92fdb35ce876499"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphene-*/
mkdir build && cd build

meson .. \
    -Dgtk_doc=false \
    -Dgobject_types=true \
    -Dintrospection=false \
    -Dtests=false \
    -Dinstalled_tests=false \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libgraphene-1", "libgraphene-1.0"], :libgraphene),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
