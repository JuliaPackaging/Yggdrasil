# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa_EGL"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.freedesktop.org/mesa/mesa.git", "1b74a12ea0ae900d49d1921ed8931eb6131e1f18"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mesa/
mkdir build
cd build
apk add py3-mako meson wayland-dev

# pkgconfig returns the wrong path here. It's an ugly hack, but it works
mkdir -p /workspace/destdir/usr/bin/
ln -s $(which wayland-scanner) /workspace/destdir/usr/bin/

meson -D egl=enabled -D gles1=enabled -D gles2=enabled -D platforms=wayland -D glx=disabled -D c_args="-Wno-implicit-function-declaration" ../ --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install

rm /workspace/destdir/usr/bin/wayland-scanner
# taken from https://metadata.ftp-master.debian.org/changelogs//main/m/mesa/mesa_20.3.5-1_copyright
install_license ../../copyright
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
    LibraryProduct("libvulkan_intel", :libvulkan_intel),
    LibraryProduct("libvulkan_lvp", :libvulkan_lvp),
    LibraryProduct("libvulkan_radeon", :libvulkan_radeon),
    LibraryProduct("libxatracker", :libxatracker),
    LibraryProduct("libgbm", :libgbm),
    LibraryProduct("libglapi", :libglapi),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("Zlib_jll"),
    Dependency("libdrm_jll"),
    Dependency("LLVM_jll"),
    Dependency("Elfutils_jll"),
    Dependency("Expat_jll"; compat="~2.2.10"),
    Dependency("Zstd_jll"),
    Dependency("Wayland_protocols_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8", julia_compat="1.6")
