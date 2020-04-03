using BinaryBuilder

name = "Blosc"
version = v"1.18.1"

# Collection of sources required to build Blosc
sources = [
    ArchiveSource("https://github.com/Blosc/c-blosc/archive/v1.18.1.tar.gz", "18730e3d1139aadf4002759ef83c8327509a9fca140661deb1d050aebba35afb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd c-blosc-1.18.1
mkdir build
cd build
CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_TESTS=OFF -DBUILD_BENCHMARKS=OFF)
CMAKE_FLAGS+=(-DBUILD_STATIC=OFF)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZLIB=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_ZSTD=ON)
CMAKE_FLAGS+=(-DPREFER_EXTERNAL_LZ4=ON)
#CMAKE_FLAGS+=(-DPREFER_EXTERNAL_SNAPPY=ON)
cmake ${CMAKE_FLAGS} ..
make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/LICENSES/BITSHUFFLE.txt
install_license ${WORKSPACE}/srcdir/LICENSES/BLOSC.txt
install_license ${WORKSPACE}/srcdir/LICENSES/FASTLZ.txt
install_license ${WORKSPACE}/srcdir/LICENSES/LZ4.txt
install_license ${WORKSPACE}/srcdir/LICENSES/SNAPPY.txt
install_license ${WORKSPACE}/srcdir/LICENSES/STDINT.txt
install_license ${WORKSPACE}/srcdir/LICENSES/ZLIB.txt
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
	Dependency("Zlib_jll"),
	Dependency("Zstd_jll"),
	Dependency("Lz4_jll"),
#	Dependency("Snappy_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
