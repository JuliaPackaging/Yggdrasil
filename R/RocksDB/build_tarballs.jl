# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "RocksDB"
version = v"8.9.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebook/rocksdb.git", "49ce8a1064dd1ad89117899839bf136365e49e79"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd rocksdb

# Apply patch for aarch
if [[ "${target}" == aarch* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/arm64.patch
fi

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DWITH_GFLAGS=0 \
    -DROCKSDB_BUILD_SHARED=1 \
    -DPORTABLE=1 \
    -DWITH_TOOLS=0 \
    -DWITH_TESTS=0 \
    -DWITH_BENCHMARK_TOOLS=0 \
    -DCMAKE_BUILD_TYPE=Release ..

cmake --build . --parallel ${nproc}
cmake --install .

install_license ../LICENSE.apache ../LICENSE.leveldb
"""

# Resolve: error: aligned allocation function of type 'void *(std::size_t, std::align_val_t)' is only available on macOS 10.13 or newer
# ...and install a newer SDK which supports `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) ∉ ("armv7l", "armv6l"), platforms)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("librocksdb", :librocksdb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="snappy_jll", uuid="fe1e1685-f7be-5f59-ac9f-4ca204017dfd"))
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
