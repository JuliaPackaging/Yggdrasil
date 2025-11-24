# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libdecor"
version = v"0.2.2"

# Collection of sources required to build libdecor
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/libdecor/libdecor/-/archive/$(version)/libdecor-$(version).tar.gz",
                  "40a1d8be07d8b1f66e8fb98a1f4a84549ca6bf992407198a5055952be80a8525"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libdecor-*/

mkdir build && cd build
meson setup .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --prefix=${prefix} \
    --buildtype=release \
    -Ddemo=false \
    -Dgtk=disabled
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> arch(p) != "armv6l" && Sys.islinux(p), supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libdecor-0", :libdecor),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("xkbcommon_jll"),
    Dependency("Dbus_jll"),
    Dependency("Libglvnd_jll"),
    Dependency("Pango_jll"; compat="1.52.2"),
    Dependency("Wayland_jll"),
    HostBuildDependency("Wayland_jll"),
    BuildDependency("Wayland_protocols_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
]

init_block = raw"""
    if Sys.islinux()
        ENV["LIBDECOR_PLUGIN_DIR"] = get(ENV, "LIBDECOR_PLUGIN_DIR", joinpath(artifact_dir, "lib", "libdecor", "plugins-1"))
    end
"""

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", init_block)
