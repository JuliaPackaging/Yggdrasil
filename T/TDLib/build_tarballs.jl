# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TDLib"
version = v"1.8.47"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tdlib/td.git", "971684a3dcc7bdf99eec024e1c4f57ae729d6d53")
]

include("../../L/libjulia/common.jl")
julia_versions = [v"1.8", v"1.9", v"1.10", v"1.11"]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/td/

install_license LICENSE_1_0.txt

find /usr/share/cmake -name "._*" -delete

mkdir build_native && cd build_native
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
    -DZLIB_LIBRARY="${host_libdir}/libz.a" \
    -DZLIB_INCLUDE_DIR="${host_includedir}" \
    ..
cmake --build . --target prepare_cross_compiling -j4

cd ${WORKSPACE}/srcdir/td/
mkdir build-cross && cd build-cross
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DNATIVE_BUILD_DIR=${WORKSPACE}/srcdir/td/build_native \
    ..
cmake --build . --target tdjson -j4
cmake --build . --target tdjson_static -j4
cmake --install .
"""

# These are the platforms we will build for by default, unless further
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtdjson", :libtdjson)
]

# Dependencies that must be installed before this package can be built
dependencies = [
	HostBuildDependency("gperf_jll"),
	HostBuildDependency("OpenSSL_jll"),
	HostBuildDependency("Zlib_jll"),

	Dependency("OpenSSL_jll"; compat="3.0.16"),
	Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9", julia_compat="1.8")
