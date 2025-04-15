using BinaryBuilder

name = "Vulkan_Headers"
version = v"1.4.312"

source = "https://github.com/KhronosGroup/Vulkan-Headers.git"
commit = "5ceb9ed481e58e705d0d9b5326537daedd06b97d"

sources = [
    GitSource(source, commit)
]

script = raw"""
cd Vulkan-Headers
install_license LICENSE.txt

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
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
