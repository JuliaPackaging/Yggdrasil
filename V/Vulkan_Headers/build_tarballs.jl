using BinaryBuilder

name = "Vulkan_Headers"
version = v"1.2.177"

source = "https://github.com/KhronosGroup/Vulkan-Headers.git"
commit = "3f437c4a94ae35af1eb93700d073e9d0e7adab3d"

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
    FileProduct("share/vulkan/registry/vk.xml", :vk_xml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
