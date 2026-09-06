using BinaryBuilder, Pkg

name = "Vulkan_Loader"
version = v"1.3.243"

sources = [
    GitSource("https://github.com/KhronosGroup/Vulkan-Loader.git",
              "22407d7804f111fbc0e31fa0db592d658e19ae8b"),
]

script = raw"""
cd Vulkan-Loader

install_license LICENSE.txt

CMAKE_FLAGS=()

# Setup cross-compilation toolchain
CMAKE_FLAGS+=(-DCMAKE_PREFIX_PATH=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Release build
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=${libdir})

if [[ "${target}" == *-apple-darwin* ]]; then
    CMAKE_FLAGS+=(-DUSE_MASM=OFF)
elif [[ "${target}" == aarch64-linux-* ]]; then
    CMAKE_FLAGS+=(-DUSE_GAS=OFF)
elif [[ "${target}" == *-mingw* ]]; then
    CMAKE_FLAGS+=(-DUSE_MASM=OFF -DENABLE_WERROR=OFF)
fi

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# X11 is not available on armv6l
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libvulkan", "libvulkan-1", "vulkan", "vulkan-1"], :libvulkan)
]

# Some dependencies are needed only on Linux or Linux and FreeBSD
linux = filter(Sys.islinux, platforms)
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Vulkan_Headers_jll"),
    Dependency("Xorg_libXrandr_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    Dependency("Wayland_jll"; platforms=linux),
    Dependency("xkbcommon_jll"; platforms=linux),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
