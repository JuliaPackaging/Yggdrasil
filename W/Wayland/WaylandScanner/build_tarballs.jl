# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "WaylandScanner"
version = v"1.23.1"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland/-/releases/$(version)/downloads/wayland-$(version).tar.xz",
                  "864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*

# We are only building for one platform and this is thus not a cross build.
# This is important since Wayland needs the wayland-scanner (which we're building here) for cross builds.
meson setup builddir \
    --prefix=${prefix} \
    -Ddocumentation=false \
    -Ddtd_validation=true \
    -Dlibraries=false \
    -Dscanner=true \
    -Dtests=false
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

#TODO platforms = supported_platforms()
# This is a host build dependency and we thus build only for that platform
platforms = [Platform("x86_64", "linux"; libc="musl")]

# The products that we will ensure are always built
products = [
    ExecutableProduct("wayland-scanner", :wayland_scanner),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"; compat="2.6.4"),
    Dependency("XML2_jll"; compat="2.13.6"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
