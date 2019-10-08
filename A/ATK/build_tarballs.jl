# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "ATK"
version = v"2.34.1"

# Collection of sources required to build ATK
sources = [
    "https://gitlab.gnome.org/GNOME/atk/-/archive/ATK_$(version.major)_$(version.minor)_$(version.patch)/atk-ATK_$(version.major)_$(version.minor)_$(version.patch).tar.bz2" =>
    "337b0a0aa3be88a79091bb023c6792e1489c187b9492777b1cc3514b0b686b8a"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/atk-*/
mkdir build && cd build

# Get a local gettext for msgfmt cross-building
apk add gettext

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
    "Glib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
