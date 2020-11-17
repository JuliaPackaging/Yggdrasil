# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa"
version = v"20.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mesa.freedesktop.org/archive/mesa-$version.tar.xz", "1f93eb1090cf71490cd0e204e04f8427a82b6ed534b7f49ca50cea7dcc89b861"),
]

# Bash recipe for building across all platforms
script = raw"""
apk add py3-mako
if [[ "${target}" == *-linux-* ]]; then
  apk add wayland-dev

  #remove wayland-scanner
  rm -r ${prefix}/bin/wayland-scanner
  mkdir -p ${prefix}/usr/bin
  ln -s /usr/bin/wayland-scanner ${prefix}/usr/bin/wayland-scanner
fi

mkdir build
cd build

# TODO: 
# - nouveau since we need LLVM build with RTTI 
# - avx2
meson ../mesa* --cross-file="${MESON_TARGET_TOOLCHAIN}" \
  -D dri-drivers=i915,i965,r100,r200 \
  -D gallium-drivers=r300,r600,radeonsi,virgl,svga,swrast,swr,iris \
  -D osmesa=gallium \
  -D b_ndebug=true \
  -D platforms=x11,wayland \
  -D vulkan-drivers=[] \
  -D swr-arches=avx \
  -D dri3=enabled \
  -D egl=enabled \

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(Sys.islinux, supported_platforms())

# Allegedly mesa builds for amc and windows


# The products that we will ensure are always built
products = [
    LibraryProduct("libdrm", :libdrm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
  Dependency("Zlib_jll"),
  Dependency("Zstd_jll"),
  Dependency("XML2_jll"),
  Dependency("Xorg_libX11_jll"),
  Dependency("Xorg_xorgproto_jll"),
  Dependency("Xorg_libxshmfence_jll"),
  Dependency("Xorg_libXrandr_jll"),
  Dependency("Xorg_libXdamage_jll"),
  Dependency("Xorg_libXxf86vm_jll"),
  Dependency("Wayland_jll"),
  Dependency("Wayland_protocols_jll"),
  Dependency("Libglvnd_jll"),
  Dependency("libdrm_jll"),
  Dependency("Elfutils_jll"),
  Dependency("glslang_jll"),

  BuildDependency("LLVM_full_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"7", preferred_llvm_version=v"8")
