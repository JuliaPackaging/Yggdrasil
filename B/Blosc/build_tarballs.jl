using BinaryBuilder

name = "Blosc"
version = v"1.21.0"

# Collection of sources required to build Blosc
sources = [
    ArchiveSource("https://github.com/Blosc/c-blosc/archive/v$(version).tar.gz", "b0ef4fda82a1d9cbd11e0f4b9685abf14372db51703c595ecd4d76001a8b342d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc-*
mkdir build
cd build
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DCMAKE_C_FLAGS="-std=c99")
CMAKE_FLAGS+=(-DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DBUILD_STATIC=OFF)
CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="")
CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_LINK_CXX_FLAGS="")
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZLIB=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZSTD=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_LZ4=ON)
#CMAKE_FLAGS+=(-DPREFER_EXTERNAL_SNAPPY=ON)
cmake ${CMAKE_FLAGS[@]} ..
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # Manually move dlls from lib/ to bin/
    mv ${prefix}/lib/*.${dlext} ${libdir}
fi

install_license ../LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc", :libblosc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	Dependency("Zlib_jll"),
	Dependency("Zstd_jll"),
	Dependency("Lz4_jll"),
	# Dependency("Snappy_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
