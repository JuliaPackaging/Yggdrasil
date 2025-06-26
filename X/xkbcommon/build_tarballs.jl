# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "xkbcommon"
version = v"1.9.2"

# Collection of sources required to build xkbcommon
sources = [
    GitSource("https://github.com/xkbcommon/libxkbcommon", "dd642359f8d43c09968e34ca7f1eb1121b2dfd70"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxkbcommon

#TODO mv $bindir/wayland-scanner $bindir/wayland-scanner_
#TODO ln -s `which wayland-scanner` $bindir
#TODO mkdir build && cd build
#TODO cp $prefix/libdata/pkgconfig/* $prefix/lib/pkgconfig || true

# Need to disable PKG_CONFIG_SYSROOT_DIR because this behaviour shows up in meson:
#
#   # Basically what happens in meson when it resolves the /workspace/destdir symlink
#   $ PKG_CONFIG_PATH=/workspace/destdir/lib/pkgconfig PKG_CONFIG_SYSROOT_DIR=/foo pkg-config --variable=wayland_scanner wayland-scanner
#   /foo/workspace/destdir/lib/pkgconfig/../../bin/wayland-scanner
#
#   # What we want to happen
#   $ PKG_CONFIG_PATH=/workspace/destdir/lib/pkgconfig PKG_CONFIG_SYSROOT_DIR='' pkg-config --variable=wayland_scanner wayland-scanner
#   /workspace/destdir/lib/pkgconfig/../../bin/wayland-scanner
#
# See:
# - https://github.com/JuliaPackaging/Yggdrasil/pull/3193#discussion_r654942322
# - https://github.com/JuliaPackaging/Yggdrasil/pull/3193#discussion_r654943148
# - https://github.com/pkgconf/pkgconf/issues/213

#TODO PKG_CONFIG_SYSROOT_DIR='' 
meson setup builddir --buildtype=release --cross-file="${MESON_TARGET_TOOLCHAIN}" -Denable-tools=false -Denable-bash-completion=false 
meson compile -C builddir
meson install -C builddir

#TODO rm $bindir/wayland-scanner
#TODO mv $bindir/wayland-scanner_ $bindir/wayland-scanner
#TODO rm -f $prefix/lib/pkgconfig/epoll-shim*.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libxkbcommon", :libxkbcommon),
    LibraryProduct("libxkbcommon-x11", :libxkbcommon_x11),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("EpollShim_jll"),
    HostBuildDependency("Wayland_jll"),
    HostBuildDependency("Wayland_protocols_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Wayland_jll"),
    Dependency("Wayland_protocols_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_xkeyboard_config_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need GCC 8 because this links to XML2, which requires GCC 8
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
