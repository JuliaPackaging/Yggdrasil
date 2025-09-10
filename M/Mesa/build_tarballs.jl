# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa"
version = v"25.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mesa3d.org/mesa-$(version).tar.xz",
                  "c124372189d35f48e049ee503029171c68962c580971cb86d968a6771c965ba4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/mesa*

apk add glslang-dev py3-mako py3-yaml

# `${bindir}/wayland_scanner` is a symbolic link that contains `..` path elements.
# These are not properly normalized: They are normalized before expanding the symbolic link `/workspace/destdir`,
# and this leads to a broken reference. We resolve the path manually.
#
# Since this symbolic link is working in the shell, and since `pkg-config` outputs the expected values,
# I think this may be a bug in `meson`.
#
# The file `wayland-scanner.pc` is mounted multiple times (and is also available via symbolic links).
# Fix it for all relevant mount points.
for destdir in /workspace/x86_64-linux-musl*/destdir; do
    prefix_path=$(echo $destdir |
                  sed -e 's+/destdir$++')/$(readlink ${host_bindir}/wayland-scanner |
                  sed -e 's+^[.][.]/[.][.]/++' |
                  sed -e 's+/bin/wayland-scanner$++')
    if [ -e ${prefix_path}/lib/pkgconfig/wayland-scanner.pc ]; then
        sed -i -e "s+prefix=.*+prefix=${prefix_path}+" ${prefix_path}/lib/pkgconfig/wayland-scanner.pc
    fi
done

# We could enable more drivers and/or build with LLVM enabled

options=()
if [[ "${target}" == *-apple-* ]]; then
    options+=(
        -Dplatforms=macos
        -Dglx=disabled
    )
fi

meson setup builddir \
    --buildtype=release \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dllvm=disabled \
    -Dgallium-drivers=softpipe \
    -Dvulkan-drivers= \
    ${options[@]}
meson compile -C builddir
meson install -C builddir

pushd licenses
install_license Apache-2.0 BSL-1.0 GPL-1.0-or-later GPL-2.0-only MIT SGI-B-2.0
popd
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# We don't know how to build for Apple platforms. We don't have X11
# libraries available, and all other build options seem cumbersome.
filter!(!Sys.isapple, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libGL", "opengl32"], :libGL),
    LibraryProduct("libEGL", :libEGL),
    LibraryProduct("libGLESv1_CM", :libGLESv1_CM),
    LibraryProduct("libGLESv2", :libGLESv2),
]

x11_platforms = filter(p -> !Sys.isapple(p) && !Sys.iswindows(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"; platforms=x11_platforms),

    BuildDependency("Xorg_glproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_kbproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_randrproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_renderproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xextproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xf86vidmodeproto_jll"; platforms=x11_platforms),
    BuildDependency("Xorg_xproto_jll"; platforms=x11_platforms),

    Dependency("Expat_jll"; compat="2.7.1"),
    Dependency("LibUnwind_jll"), # no compat entry to support all architectures and Julia versions
    Dependency("Libglvnd_jll"; compat="1.7.1", platforms=x11_platforms),
    Dependency("Wayland_jll"; compat="1.24.0", platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXau_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXdmcp_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXxf86vm_jll"; platforms=x11_platforms),
    Dependency("Xorg_libxcb_jll"; platforms=x11_platforms),
    Dependency("Xorg_libxshmfence_jll"; platforms=x11_platforms),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("libdrm_jll"; compat="2.4.125", platforms=x11_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
