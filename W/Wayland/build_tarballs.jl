# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Wayland"
version = v"1.23.0"

# Collection of sources required to build Wayland
sources = [
   GitSource("https://gitlab.freedesktop.org/wayland/wayland.git",
             "a9fec8dd65977c57f4039ced34327204d9b9d779"),
]

bootstrap = true

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wayland/

if [[ "${target}" == x86_64-linux-* ]]; then
   mkdir bootstrap
   cd bootstrap
   
   meson setup .. \
         --buildtype=release \
         -Ddocumentation=false \
         -Dtests=false
   meson compile
   meson install
   
   cd ../
fi

mkdir build
cd build

meson setup .. \
      --prefix=${prefix} \
      --buildtype=release \
      --cross-file="${MESON_TARGET_TOOLCHAIN}" \
      -Ddocumentation=false \
      -Dtests=false
meson compile
meson install
# rm -f $prefix/lib/pkgconfig/epoll-shim*.pc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
if bootstrap
   platforms = supported_platforms(; exclude=p -> !Sys.islinux(p) || arch(p) != "x86_64")
else
   platforms = supported_platforms(; exclude=p -> arch(p) == "armv6l" || (!Sys.islinux(p) && !Sys.isfreebsd(p)))
end

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

if !bootstrap
   push!(dependencies, HostBuildDependency("Wayland_jll"))
end

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
