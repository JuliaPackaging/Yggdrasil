# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa"
version = v"20.2.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mesa.freedesktop.org/archive/mesa-$version.tar.xz", "1f93eb1090cf71490cd0e204e04f8427a82b6ed534b7f49ca50cea7dcc89b861"),
    DirectorySource("bundled")
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

pushd $WORKSPACE/srcdir/mesa-*
# mv ${WORKSPACE}/srcdir/tools/llvm-config ${WORKSPACE}/destdir/bin/
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

mkdir subprojects/llvm

cp ${WORKSPACE}/srcdir/meson.build subprojects/llvm/

if [[ ${target} == *linux* ]]; then
  # TODO: 
  # - nouveau since we need LLVM build with RTTI 
  # - avx2
  PLATFORMS=x11,wayland
  DRI=r100,r200 #nouveau
  GALLIUM=r300,r600,radeonsi,virgl,swrast #zink,nouveau,freedreno
  SWR=

  # We live in an Intel world
  if [[ ${target} == *x86_64* ]] || [[ ${target} == *i686* ]]; then
      DRI=i915,i965,${DRI}
      GALLIUM=swr,svga,iris,${GALLIUM}
      SWR_ARCHES=avx #avx2
  fi

  if [[ ${target} == *aarch64* ]]; then
      GALLIUM=kmsro,lima,panfrost,v3d,vc4,${GALLIUM}
  fi

  if [[ ${target} == *armv7l* ]]; then
      GALLIUM=etnaviv,kmsro,lima,panfrost,tegra,v3d,vc4,${GALLIUM}
  fi

  if [[ ${target} == *armv6l* ]]; then
      GALLIUM=vc4,${GALLIUM}
  fi

else
    PLATFORMS=
    DRI=
    GALLIUM=
    SWR=
fi

meson build --cross-file="${MESON_TARGET_TOOLCHAIN}" \
  -D shared-llvm=enabled \
  -D dri-drivers=${DRI} \
  -D gallium-drivers=${GALLIUM} \
  -D osmesa=gallium \
  -D b_ndebug=true \
  -D buildtype=release \
  -D strip=true \
  -D platforms=${PLATFORMS} \
  -D vulkan-drivers=[] \
  -D swr-arches=${SWR_ARCHES} \
  -D dri3=enabled \
  -D egl=enabled \

ninja -C build -j${nproc}
ninja -C build install

install_license docs/license.rst
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# Elfutils is missing on musl platforms
platforms = filter(p->Sys.islinux(p) && libc(p) != "musl", supported_platforms())

# Allegedly mesa builds for amc and windows


# The products that we will ensure are always built
products = [
    LibraryProduct("libGL", :libGL),
    LibraryProduct("libEGL", :libEGL),
    LibraryProduct("libGLX", :libGLX),
    LibraryProduct("libOSMesa", :libOSMesa),
]

# Dependencies that must be installed before this package can be built
dependencies = [
  Dependency("Zlib_jll"),
  Dependency("Zstd_jll"),
  Dependency("XML2_jll"),
  Dependency("Xorg_libX11_jll"),
  BuildDependency("Xorg_xorgproto_jll"),
  Dependency("Xorg_libxshmfence_jll"),
  Dependency("Xorg_libXrandr_jll"),
  Dependency("Xorg_libXdamage_jll"),
  Dependency("Xorg_libXxf86vm_jll"),
  Dependency("Wayland_jll"),
  BuildDependency("Wayland_protocols_jll"),
  Dependency("Libglvnd_jll"),
  Dependency("libdrm_jll"),
  Dependency("Elfutils_jll"),
  Dependency("glslang_jll"),

  # Actual runtime dependency but we gonna rely on Julia for it
  BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"9.0.1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"7", preferred_llvm_version=v"8")
