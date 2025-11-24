# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Wayland"
version = v"1.24.0"

# Collection of sources required to build Wayland
sources = [
    ArchiveSource("https://gitlab.freedesktop.org/wayland/wayland/-/releases/$(version)/downloads/wayland-$(version).tar.xz",
                  "82892487a01ad67b334eca83b54317a7c86a03a89cfadacfef5211f11a5d0536"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland-*/

mkdir build-host
cd build-host

# Hack to make the pkgconfig paths work on the host build
ln -s /workspace /workspace/destdir
# Avoid parasitic linking on freebsd, somehow $prefix/lib ends up in /opt/x86_64-linux-musl/x86_64-linux-musl/sys-root/usr/local/lib
mv $prefix/lib $prefix/lib_

meson .. \
    --native-file="${MESON_HOST_TOOLCHAIN}" \
    --prefix ${host_prefix} --pkg-config-path ${host_prefix}/lib/pkgconfig \
    -Ddocumentation=false \
    -Ddtd_validation=false
ninja -j${nproc}
ninja install
rm /workspace/destdir/workspace
cd ..

mv $prefix/lib_ $prefix/lib

mkdir build-wayland

cd build-wayland
# setting dtd_validation=false to avoid requiring libxml2
CMAKE=/usr/bin/cmake meson .. \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Ddocumentation=false \
    -Ddtd_validation=false
ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms())

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
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Libffi_jll"; compat="~3.4.7"),
    Dependency("EpollShim_jll"; platforms=filter(Sys.isfreebsd, platforms)),
    HostBuildDependency(PackageSpec("Expat_jll", v"2.6.5")),
    HostBuildDependency(PackageSpec("Libffi_jll", v"3.4.7")),
    HostBuildDependency("EpollShim_jll"; platforms=filter(Sys.isfreebsd, platforms)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"5", julia_compat="1.6")
