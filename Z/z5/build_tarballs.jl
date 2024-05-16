# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase, Pkg

name = "z5"
version = v"2.0.17"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/constantinpape/z5", "90ffc7524de5b179c82920f3304ec46287b6d210"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/z5

# CMAKE_FLAGS=()
# if [[ ${target} = arm-* ]]; then
#    # Not even GCC 13 can compile for 32-bit ARM
#    CMAKE_FLAGS+=(-DAOM_TARGET_CPU=generic)
# fi

# ${CMAKE_FLAGS[@]}

cmake -B build-dir -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_Z5PY=OFF \
    -DWITH_BLOSC=ON \
    -DWITH_BZIP2=ON \
    -DWITH_GCS=ON \
    -DWITH_LZ4=ON \
    -DWITH_MARRAY=ON \
    -DWITH_XZ=ON \
    -DWITH_ZLIB=ON
# Other possible options:
#     WITH_S3

cmake --build build-dir --parallel ${nproc}
cmake --install build-dir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libz5", :libz5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="nlohman_json_jll", uuid="7c7c7bd4-5f1c-5db3-8b3f-fcf8282f06da")),
    BuildDependency(PackageSpec(name="xsimd_jll", uuid="9e151094-6d0c-5a5c-8bf5-2fcad2e63db9")),
    BuildDependency(PackageSpec(name="xtensor_jll", uuid="e692580d-a894-5e11-adde-c3d453d9283f")),
    BuildDependency(PackageSpec(name="xtl_jll", uuid="ba385536-920d-53da-b5db-5183e89bfaf8")),
    Dependency("Blosc_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Lz4_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
