# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Graphene"
version = v"1.10.8"

# Collection of sources required to build Graphene
sources = [
    GitSource("https://github.com/ebassi/graphene", "4e2578450809c2099400cf85caf18eafcd7100aa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/graphene
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libgraphene-1", "libgraphene-1.0"], :libgraphene),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"; compat="2.84.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6")
