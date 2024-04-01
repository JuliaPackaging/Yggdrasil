# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ATK"
version = v"2.38.0"

# Collection of sources required to build ATK
sources = [
    ArchiveSource("https://download.gnome.org/sources/atk/$(version.major).$(version.minor)/atk-$(version).tar.xz",
                  "ac4de2a4ef4bd5665052952fe169657e65e895c5057dffb3c2a810f6191a0c36"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atk-*/
mkdir build && cd build
meson .. -Dintrospection=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libatk-1", "libatk-1.0"], :libatk),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need host gettext for msgfmt
    HostBuildDependency("Gettext_jll"),
    Dependency("Glib_jll", v"2.68.1"; compat="^2.38.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
