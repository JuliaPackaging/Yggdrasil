using BinaryBuilder

name = "Blosc"
version = v"1.21.5"

# Collection of sources required to build Blosc
sources = [
    GitSource("https://github.com/Blosc/c-blosc.git", "d306135aaf378ade04cd4d149058c29036335758"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc
if [[ "${target}" == *mingw* ]]; then
  atomic_patch -p1 ../patches/mingw.patch
fi
mkdir build
cd build
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_C_FLAGS="-std=gnu99")
CMAKE_FLAGS+=(-DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DBUILD_STATIC=OFF)
CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="")
CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="")
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZLIB=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZSTD=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_LZ4=ON)
cmake ${CMAKE_FLAGS[@]} ..
make -j${nproc}
make install

install_license ../LICENSES/*.txt
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
	Dependency("Zlib_jll"; compat="1.2.12"),
	Dependency("Zstd_jll"; compat="1.5.0"),
	Dependency("Lz4_jll"; compat="1.9.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
