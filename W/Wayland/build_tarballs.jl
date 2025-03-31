# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.23.1"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland/-/releases/$(version)/downloads/wayland-$(version).tar.xz",
                  "864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*/

mkdir build-host
cd build-host
meson .. \
    --native-file="${MESON_HOST_TOOLCHAIN}" \
    --prefix ${host_prefix} \
    -Ddocumentation=false
ninja -j${nproc}
ninja install
cd ..

mkdir build-wayland

cd build-wayland
meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Ddocumentation=false
ninja -j${nproc}
ninja install
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
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
# Build trigger: 1
