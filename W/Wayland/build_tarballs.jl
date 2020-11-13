# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.17.0"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://wayland.freedesktop.org/releases/wayland-$(version).tar.xz",
                  "72aa11b8ac6e22f4777302c9251e8fec7655dc22f9d94ee676c6b276f95f91a4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*/

# We need to run `wayland-scanner` on the host system
apk add wayland-dev

atomic_patch -p1 ../patches/Makefile_in.patch
./configure --prefix=${prefix} --host=${target} --disable-documentation --with-host-scanner
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if Sys.islinux(p)]

# The products that we will ensure are always built
products = [
    ExecutableProduct("wayland-scanner", :wayland_scanner),
    LibraryProduct("libwayland-client", :libwayland_client),
    LibraryProduct("libwayland-cursor", :libwayland_cursor),
    LibraryProduct("libwayland-egl", :libwayland_egl),
    LibraryProduct("libwayland-server", :libwayland_server),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Expat_jll"),
    Dependency("Libffi_jll"),
    Dependency("XML2_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
