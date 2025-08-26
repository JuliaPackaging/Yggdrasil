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

meson setup builddir \
    --buildtype=release \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dllvm=disabled \
    -Dgallium-drivers=softpipe \
    -Dvulkan-drivers=
meson compile -C builddir
meson install -C builddir

pushd licenses
install_license Apache-2.0 BSL-1.0 GPL-1.0-or-later GPL-2.0-only MIT SGI-B-2.0
popd
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# darwin: we need X11, but we only build X11 for Linux and FreeBSD
# freebsd: libdrm is not built

# The products that we will ensure are always built
products = [
    # Products on Linux:
    # libEGL
    # libEGL_mesa
    # libGLESv1_CM
    # libGLESv2
    # libGLX
    # libGLX_mesa
    # libGLdispatch
    # libOpenGL

    # Products on Windows:
    # libEGL
    # libGLESv1_CM
    # libGLESv2
    # libgallium_wgl
    # opengl32

    LibraryProduct(["libGL", "opengl32"], :libGL),

    #TODO LibraryProduct("opengl32sw", :opengl32sw; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"),

    BuildDependency("Xorg_glproto_jll"),
    BuildDependency("Xorg_kbproto_jll"),
    BuildDependency("Xorg_randrproto_jll"),
    BuildDependency("Xorg_renderproto_jll"),
    BuildDependency("Xorg_xextproto_jll"),
    BuildDependency("Xorg_xf86vidmodeproto_jll"),
    BuildDependency("Xorg_xproto_jll"),

    Dependency("Expat_jll"; compat="2.7.1"),
    Dependency("LibUnwind_jll"), # no compat entry to support all architectures and Julia versions
    Dependency("Libglvnd_jll"; compat="1.7.1"),
    Dependency("Wayland_jll"; compat="1.24.0"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXau_jll"),
    Dependency("Xorg_libXdmcp_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Xorg_libXxf86vm_jll"),
    Dependency("Xorg_libxcb_jll"),
    Dependency("Xorg_libxshmfence_jll"),
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
    Dependency("libdrm_jll"; compat="2.4.125"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
