using BinaryBuilder

name = "Blosc"
version = v"1.21.6"

# Collection of sources required to build Blosc
sources = [
    GitSource("https://github.com/Blosc/c-blosc.git", "616f4b7343a8479f7e71dd3d7025bd92c9a6bbd0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc
if [[ "${target}" == *mingw* ]]; then
  atomic_patch -p1 ../patches/mingw.patch
fi
CMAKE_FLAGS=(
    -Bbuild
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=$prefix
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_C_FLAGS="-std=gnu99"
    -DBUILD_BENCHMARKS=OFF
    -DBUILD_STATIC=OFF
    -DBUILD_TESTS=OFF
    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS=""
    -DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS=""
    -DPREFER_EXTERNAL_LZ4=ON
    -DPREFER_EXTERNAL_ZLIB=ON
    -DPREFER_EXTERNAL_ZSTD=ON
)
cmake ${CMAKE_FLAGS[@]}
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc", :libblosc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Lz4_jll"; compat="1.10.0"),
    Dependency("Zlib_jll"; compat="1.3.1"),
    Dependency("Zstd_jll"; compat="1.5.6"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
