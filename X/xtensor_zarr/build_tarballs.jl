# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "xtensor_zarr"
version = v"0.0.7"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/xtensor-stack/xtensor-zarr", "ad048585b53bb3f3f4442d1853b0ae4576adc889"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xtensor-zarr
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DXTENSOR_ZARR_BUILD_STATIC_LIBS=OFF \
    -DXTENSOR_ZARR_DISABLE_ARCH_NATIVE=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
    # This is a header-only library without any binary products
    FileProduct("include/xtensor-zarr/xzarr-array.hpp", :xarr_array),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Blosc_jll"),
    Dependency("GDAL_jll"),
    Dependency("Zlib_jll"),
    Dependency("ghcfilesystem_jll"), # https://github.com/gulrak/filesystem
    Dependency("nlohmann_json_jll"),
    Dependency("xtensor_io_jll"),
    Dependency("xtensor_jll"),
    Dependency("zarray_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
