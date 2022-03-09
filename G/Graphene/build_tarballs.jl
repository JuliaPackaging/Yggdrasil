# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Graphene"
version = v"1.10.6"

# Collection of sources required to build Graphene
sources = [
    ArchiveSource("https://github.com/ebassi/graphene/releases/download/$(version)/graphene-$(version).tar.xz",
                  "80ae57723e4608e6875626a88aaa6f56dd25df75024bd16e9d77e718c3560b25"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphene-*/
mkdir build && cd build
meson .. \
    -Dgtk_doc=false \
    -Dgobject_types=true \
    -Dintrospection=disabled \
    -Dtests=false \
    -Dinstalled_tests=false \
    --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libgraphene-1", "libgraphene-1.0"], :libgraphene),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"; compat="2.68.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
