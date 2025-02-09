# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsigcpp"
version = v"3.6.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/libsigc++/3.6/libsigc%2B%2B-$(version).tar.xz",
                  "c3d23b37dfd6e39f2e09f091b77b1541fbfa17c4f0b6bf5c89baef7229080e17")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsigc++*
mkdir meson
cd meson
meson --cross-file=${MESON_TARGET_TOOLCHAIN%.*}_gcc.meson
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsigc-3.0", "libsigc-3"], :libsigc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7.1.0")
