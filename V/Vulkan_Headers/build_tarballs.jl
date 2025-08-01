using BinaryBuilder, Pkg

name = "Vulkan_Headers"
version = v"1.4.321"

source = "https://github.com/KhronosGroup/Vulkan-Headers.git"
commit = "2cd90f9d20df57eac214c148f3aed885372ddcfe"

sources = [
    GitSource(source, commit)
]

script = raw"""
apk del cmake

cd Vulkan-Headers
install_license LICENSE.md

CMAKE_FLAGS=()

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_LIBDIR=${libdir})

cmake -B build -S . -GNinja ${CMAKE_FLAGS[@]}
ninja -C build -j ${nproc} install
"""

# platforms = supported_platforms()
platforms = [AnyPlatform()]


# The products that we will ensure are always built
products = Product[
    FileProduct("share/vulkan/registry/vk.xml", :vk_xml),
    FileProduct("include/vulkan/vulkan.hpp", :vulkan_hpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = v"3.31.6")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
