# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsigcpp"
version = v"3.0.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/libsigc++/3.0/libsigc%2B%2B-$(version).tar.xz",
                  "bfbe91c0d094ea6bbc6cbd3909b7d98c6561eea8b6d9c0c25add906a6e83d733")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libsigc++*/
mkdir meson
cd meson
meson --cross-file=${MESON_TARGET_TOOLCHAIN}
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct(["libsigc-3.0", "libsigc-3"], :libsigc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7.1.0")
