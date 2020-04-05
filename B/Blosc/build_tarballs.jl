using BinaryBuilder

name = "Blosc"
version = v"1.14.3"

# Collection of sources required to build Blosc
sources = [
    ArchiveSource("https://github.com/Blosc/c-blosc/archive/v$(version).tar.gz", "7217659d8ef383999d90207a98c9a2555f7b46e10fa7d21ab5a1f92c861d18f7"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc-*
mkdir build
cd build
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
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
#	Dependency("Snappy_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
