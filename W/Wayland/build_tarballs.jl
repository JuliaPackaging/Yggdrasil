# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.22.0"

# Collection of sources required to build Wayland
sources = [
   GitSource("https://gitlab.freedesktop.org/wayland/wayland.git",
             "b2649cb3ee6bd70828a17e50beb16591e6066288"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland/

# We need to run `wayland-scanner` of the same version on the host system Alpine v3.18 has v1.22
# apk add wayland-dev --repository=http://dl-cdn.alpinelinux.org/alpine/v3.20/main

# ln -s `which wayland-scanner` $bindir
# cp $prefix/libdata/pkgconfig/* $prefix/lib/pkgconfig || true

meson build/ \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Ddocumentation=false
# ninja -j${nproc}
ninja -C build/ install
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
    # HostBuildDependency("Wayland_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
