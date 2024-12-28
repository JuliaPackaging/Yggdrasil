# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.21.0"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland/-/releases/$(version)/downloads/wayland-$(version).tar.xz",
                  "6dc64d7fc16837a693a51cfdb2e568db538bfdc9f457d4656285bb9594ef11ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*/

ln -s `which wayland-scanner` $bindir
cp $prefix/libdata/pkgconfig/* $prefix/lib/pkgconfig || true

mkdir build-wayland

cd build-wayland
meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Ddocumentation=false
ninja -j${nproc}
ninja install
rm -f $prefix/lib/pkgconfig/epoll-shim*.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> arch(p) != "armv6l" && (Sys.islinux(p) || Sys.isfreebsd(p)), supported_platforms())

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
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
    Dependency("XML2_jll"),
    Dependency("EpollShim_jll"),
    HostBuildDependency("Wayland_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
# Build trigger: 1
