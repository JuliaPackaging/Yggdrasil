# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsigcpp"
version = v"2.12.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/libsigc++/2.12/libsigc%2B%2B-$(version).tar.xz",
                  "1c466d2e64b34f9b118976eb21b138c37ed124d0f61497df2a90ce6c3d9fa3b5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsigc++*/
mkdir meson
cd meson
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(); skip=Returns(false))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsigc-2.0", "libsigc-2"], :libsigc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
