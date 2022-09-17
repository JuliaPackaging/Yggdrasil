# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_image"
version = v"2.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www.libsdl.org/projects/SDL_image/release/SDL2_image-$(version).zip",
                  "efe3c229853d0d40c35e5a34c3f532d5d9728f0abc623bc62c962bcef8754205"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2_image-*/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DSDL2_IMAGE_WEBP=ON -DSDL2_IMAGE_TIF=ON SDL2IMAGE_BACKEND_IMAGEIO=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_image", "SDL2_image"], :libsdl2_image)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf"))
    Dependency(PackageSpec(name="libwebp_jll", uuid="c5f90fcd-3b7e-5836-afba-fc50a0988cb2"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;julia_compat="1.6")
