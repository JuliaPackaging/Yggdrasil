# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa_EGL"
version = v"22.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.freedesktop.org/mesa/mesa.git", "716fc5280adcb1912c817298353c0edc731e76a8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mesa/

# Note: Currently unused, until `LIBPATH` becomes updated with search path of products with `dont_dlopen=true`
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/relative-dlopen.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/static_assert.patch

apk add py3-mako

mkdir build
cd build

# Make a cross-file for llvm-config
echo "[binaries]" >llvm-cross.ini
echo "llvm-config = '${host_prefix}/tools/llvm-config'" >>llvm-cross.ini

# Ensure pkg-config sees our Wayland configs
export PKG_CONFIG_PATH=${host_libdir}/pkgconfig:$PKG_CONFIG_PATH

# Fixup paths in Wayland pkg-config files
sed -i "s?prefix=.*?prefix=${host_prefix}?" "${host_prefix}/lib/pkgconfig/wayland-scanner.pc"
sed -i "s?prefix=.*?prefix=${host_prefix}?" "${host_prefix}/lib/pkgconfig/wayland-client.pc"
sed -i "s?prefix=.*?prefix=${host_prefix}?" "${host_prefix}/lib/pkgconfig/wayland-server.pc"

meson -D egl=enabled \
      -D gles1=enabled \
      -D gles2=enabled \
      -D opengl=true \
      -D platforms=x11,wayland \
      -D glx=dri \
      -D c_args="-Wno-implicit-function-declaration" \
      -D cpp_rtti=false \
      ../ \
      --cross-file="${MESON_TARGET_TOOLCHAIN}" \
      --cross-file=llvm-cross.ini
ninja -j${nproc}
ninja install

# taken from https://metadata.ftp-master.debian.org/changelogs//main/m/mesa/mesa_20.3.5-1_copyright
install_license ../../copyright
"""

# TODO: Hack to ensure we load the right drivers
init_block = """
ENV["LIBGL_DRIVERS_PATH"] = joinpath(artifact_dir, "lib", "dri")
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libEGL", :libEGL),
    LibraryProduct("libGLESv1_CM", :libGLESv1_CM),
    LibraryProduct("libGLESv2", :libGLESv2),
    LibraryProduct("libGL", :libGL),
    LibraryProduct("libvulkan_intel", :libvulkan_intel),
    LibraryProduct("libvulkan_lvp", :libvulkan_lvp),
    LibraryProduct("libvulkan_radeon", :libvulkan_radeon),
    LibraryProduct("libxatracker", :libxatracker),
    LibraryProduct("libgbm", :libgbm),
    LibraryProduct("libglapi", :libglapi),

    # Drivers
    LibraryProduct("crocus_dri", :crocus_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("iris_dri", :iris_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("libgallium_dri", :libgallium_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("r300_dri", :r300_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("radeonsi_dri", :radeonsi_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("virtio_gpu_dri", :virtio_gpu_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("i915_dri", :i915_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("kms_swrast_dri", :kms_swrast_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("nouveau_dri", :nouveau_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("r600_dri", :r600_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("swrast_dri", :swrast_dri, ["lib/dri"]; dont_dlopen=true),
    LibraryProduct("vmwgfx_dri", :vmwgfx_dri, ["lib/dri"]; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Wayland_jll"),
    Dependency("libLLVM_jll"; compat="11.0.0"),
    HostBuildDependency(PackageSpec(;name="LLVM_jll", version=v"11.0.1")),
    Dependency("Zlib_jll"),
    Dependency("libdrm_jll"; compat="2.4.110"),
    Dependency("Elfutils_jll"),
    Dependency("Expat_jll"; compat="2.2.10"),
    Dependency("Zstd_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_libXext_jll"),
    Dependency("Xorg_libXfixes_jll"),
    Dependency("Xorg_libxshmfence_jll"),
    Dependency("Xorg_libXxf86vm_jll"),
    Dependency("Xorg_xf86vidmodeproto_jll"),
    Dependency("Xorg_libXrandr_jll"),
    Dependency("Wayland_protocols_jll"; compat="1.24"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6", init_block)
