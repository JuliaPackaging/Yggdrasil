# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "at_spi2_core"
version = v"2.34.0"

# Collection of sources required to build at-spi2-core
sources = [
    "http://ftp.gnome.org/pub/gnome/sources/at-spi2-core/$(version.major).$(version.minor)/at-spi2-core-$(version).tar.xz" =>
    "d629cdbd674e539f8912028512af583990938c7b49e25184c126b00121ef11c6"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/at-spi2-core-*/
mkdir build && cd build

# Get a local gettext for msgfmt cross-building
apk add gettext

meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=no \
    -Dx11=yes \
    -Dsystemd_user_dir=no
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]

# The products that we will ensure are always built
products = [
    LibraryProduct("libatspi", :libatspi),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Dbus_jll",
    "Glib_jll",
    "Xorg_libXtst_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
