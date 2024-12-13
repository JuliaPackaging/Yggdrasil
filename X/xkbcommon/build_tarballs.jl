# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "xkbcommon"
version = v"1.4.1"

# Collection of sources required to build xkbcommon
sources = [
    ArchiveSource("https://xkbcommon.org/download/libxkbcommon-$(version).tar.xz",
                  "943c07a1e2198026d8102b17270a1f406e4d3d6bbc4ae105b9e1b82d7d136b39"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbcommon-*/
mv $bindir/wayland-scanner $bindir/wayland-scanner_
ln -s `which wayland-scanner` $bindir
mkdir build && cd build
cp $prefix/libdata/pkgconfig/* $prefix/lib/pkgconfig || true
meson .. --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Denable-docs=false
ninja -j${nproc}
ninja install
rm $bindir/wayland-scanner
mv $bindir/wayland-scanner_ $bindir/wayland-scanner
rm -f $prefix/lib/pkgconfig/epoll-shim*.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> arch(p) != "armv6l" && (Sys.islinux(p) || Sys.isfreebsd(p)), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libxkbcommon", :libxkbcommon),
    LibraryProduct("libxkbcommon-x11", :libxkbcommon_x11),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_xkeyboard_config_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Wayland_jll"),
    Dependency("Wayland_protocols_jll"),
    BuildDependency("EpollShim_jll"),
    HostBuildDependency("Wayland_jll"),
    HostBuildDependency("Wayland_protocols_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
# Build trigger: 1
