# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"
version = v"1.9.9"

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "f06319ce93654e7cada64a75778fb50e8ddc6667")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd c-blosc2/
mkdir build
cd build/
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DBUILD_EXAMPLES=OFF -DBUILD_STATIC=OFF)
CMAKE_FLAGS+=(-DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="")
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZLIB=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZSTD=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_LZ4=ON)
cmake ${CMAKE_FLAGS[@]} ..
make -j${nproc}
make install
install_license ../LICENSES/*.txt
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
	Dependency("Zlib_jll"),
	Dependency("Zstd_jll"),
	Dependency("Lz4_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", lock_microarchitecture=false, preferred_gcc_version=v"5.2")
