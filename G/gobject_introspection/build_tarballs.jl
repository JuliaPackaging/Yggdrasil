# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "gobject_introspection"
version = v"1.72.0"

sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/gobject-introspection/$(version.major).$(version.minor)/gobject-introspection-$(version).tar.xz",
              "02fe8e590861d88f83060dd39cda5ccaa60b2da1d21d0f95499301b186beaabc"),
]

# Bash recipe for building across all platforms
script = raw"""
# We need to run some commands with a native Python
apk add python3-dev

# We use the build system's version of gi-scanner to generate XML for glib
apk add gobject-introspection-dev

cd $WORKSPACE/srcdir/gobject-*/

mkdir build-gi

cd build-gi
meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dgi_cross_use_prebuilt_gi=true
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> triplet(p) == "x86_64-linux-gnu", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgirepository-1.0", :libgirepository),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Glib_jll"; compat="2.68.3")
    ]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
