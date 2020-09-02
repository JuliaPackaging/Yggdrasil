using BinaryBuilder

name = "Vulkan_Headers"
version = v"1.2.151"

source = "https://github.com/KhronosGroup/Vulkan-Headers.git"
commit = "99638d8d7fc64ae9c3fc6a396ec034abd40e675d" # August 19th, 2020

sources = [
    GitSource(source, commit)
]

script_unix = raw"""
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

build_tarballs(ARGS, name, version, sources, script_unix, platforms, products, dependencies)