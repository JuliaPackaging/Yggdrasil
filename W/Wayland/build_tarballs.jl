# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.23.0"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland/-/releases/$(version)/downloads/wayland-$(version).tar.xz",
                  "05b3e1574d3e67626b5974f862f36b5b427c7ceeb965cb36a4e6c2d342e45ab2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*/

# Build a native version of wayland-scanner
PKG_CONFIG_SYSROOT_DIR='' \
PKG_CONFIG_PATH="${host_libdir}/pkgconfig" \
meson setup host_build . \
    --native-file="${MESON_HOST_TOOLCHAIN}" \
    --buildtype=plain \
    -Ddtd_validation=false \
    -Dlibraries=false \
    -Dscanner=true \
    -Ddocumentation=false \
    -Dtests=false
ninja -C host_build -j${nproc}
ninja -C host_build install

# Then cross-compile the library, which will use the native wayland-scanner during build

if [[ "$target" =~ "freebsd" ]]; then
    # add location of epollshim pkg-config file
    export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:$prefix/libdata/pkgconfig"
fi
meson setup build . \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dlibraries=true \
    -Dscanner=true \
    -Ddocumentation=false \
    -Dtests=false
ninja -C build -j${nproc}
ninja -C build install
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
    HostBuildDependency("Expat_jll"#=; compat="2.6.4"=#),  # fixed pkg-config prefix
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Libffi_jll"; compat="~3.2.2"),
    Dependency("XML2_jll"),
    Dependency("EpollShim_jll"; platforms = filter(Sys.isfreebsd, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
# Build trigger: 1
