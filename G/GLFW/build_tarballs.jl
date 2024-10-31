using BinaryBuilder

name = "GLFW"
version = "3.4"

# Collection of sources required to build glfw
sources = [
    ArchiveSource("https://github.com/glfw/glfw/releases/download/$(version)/glfw-$(version).zip",
                  "b5ec004b2712fd08e8861dc271428f048775200a2df719ccf575143ba749a3e9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glfw-*/
mkdir build && cd build

# Building with Wayland fails on FreeBSD because it's missing some headers (e.g. linux/input.h)
if [[ ${target} == *linux* ]]; then
    export WAYLAND_ENABLED=ON
else
    export WAYLAND_ENABLED=OFF
fi

# On FreeBSD we need to set __BSD_VISIBLE to enable ppoll() in the system headers
if [[ ${target} == *freebsd* ]]; then
   export BSD_VISIBLE=1
else
   export BSD_VISIBLE=0
fi

# We need _POSIX_C_SOURCE >= 199309L for `CLOCK_MONOTONIC`, and >= 200809L for `O_CLOEXEC`.
# See:
# - https://github.com/glfw/glfw/issues/1988
# - https://github.com/glfw/glfw/issues/2495
CFLAGS="-D_POSIX_C_SOURCE='200809L' -D__BSD_VISIBLE=${BSD_VISIBLE}" cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DGLFW_BUILD_EXAMPLES=false \
    -DGLFW_BUILD_TESTS=false \
    -DGLFW_BUILD_DOCS=OFF \
    -DGLFW_BUILD_WAYLAND=${WAYLAND_ENABLED}

# Cmake insists on finding the `wayland-scanner` binary built for the target
# platform, so we have to explicitly override it to use the binary for the host.
cmake -DWAYLAND_SCANNER_EXECUTABLE="$host_bindir/wayland-scanner" ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libglfw", "glfw3"], :libglfw)
]

x11_platforms = filter(p->Sys.islinux(p) || Sys.isfreebsd(p), platforms)
wayland_platforms = filter(Sys.islinux, platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"; platforms=wayland_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    Dependency("libdecor_jll"; platforms=wayland_platforms),
    Dependency("xkbcommon_jll"; platforms=wayland_platforms),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, VersionNumber(version), sources, script, platforms, products, dependencies; julia_compat="1.6")
