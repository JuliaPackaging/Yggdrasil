# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "RocksDB"
version = v"11.1.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/facebook/rocksdb.git",
              "3b446089141659fad25328c5ea3e7ed283df46e4"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/rocksdb*

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_PREFIX_PATH=${prefix}
    -DPORTABLE=1
    -DROCKSDB_BUILD_SHARED=1
    -DWITH_GFLAGS=0
    -DWITH_TESTS=0
    -DWITH_TOOLS=0
    -DWITH_CORE_TOOLS=0
    -DWITH_BENCHMARK_TOOLS=0
    -DFAIL_ON_WARNINGS=0
    # Compression backends: enable the full set RocksDB supports through the
    # BinaryBuilder-provided JLLs.
    -DWITH_SNAPPY=1
    -DWITH_ZLIB=1
    -DWITH_BZ2=1
    -DWITH_LZ4=1
    -DWITH_ZSTD=1
)

# RocksDB's CMakeLists.txt gates its entire install() ruleset behind
# `if(NOT WIN32 OR ROCKSDB_INSTALL_ON_WINDOWS)`, and ROCKSDB_INSTALL_ON_WINDOWS
# defaults OFF -- without this, `cmake --install .` is a silent no-op on
# Windows and the resulting tarball is empty.
if [[ "${target}" == *mingw* ]]; then
    CMAKE_FLAGS+=(-DROCKSDB_INSTALL_ON_WINDOWS=1)
fi

# jemalloc (WITH_JEMALLOC) was tried and deliberately left disabled: RocksDB's
# env/io_posix.cc calls glibc's getline() (which allocates via glibc malloc)
# and then free()s that buffer through a macro that redefines free() to
# je_free() under WITH_JEMALLOC, freeing memory jemalloc never allocated --
# a reproducible segfault in PosixHelper::GetQueueSysfsFileValueOfFd on every
# DB::Open. This is an upstream RocksDB/jemalloc incompatibility, not
# specific to this recipe.

# io_uring gives RocksDB a faster async I/O backend on Linux. Upstream
# defaults WITH_LIBURING=ON but it silently no-ops unless liburing is
# actually discoverable; we supply it via Liburing_jll on Linux only.
if [[ "${target}" == *linux* ]]; then
    CMAKE_FLAGS+=(-DWITH_LIBURING=1)
else
    CMAKE_FLAGS+=(-DWITH_LIBURING=0)
fi

mkdir build && cd build
cmake "${CMAKE_FLAGS[@]}" ..
cmake --build . --parallel ${nproc}
cmake --install .

install_license ../LICENSE.Apache ../LICENSE.leveldb ../COPYING
"""

# Resolve: error: aligned allocation function of type 'void *(std::size_t, std::align_val_t)' is only available on macOS 10.13 or newer
# ...and install a newer SDK which supports `std::filesystem`
sources, script = require_macos_sdk("10.15", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line. 32-bit ARM is excluded
# (RocksDB targets 64-bit platforms); Windows and aarch64 are both included
# and have been locally build-tested end to end -- neither needs the old
# arm64.patch (util/crc32c_arm64.cc's HAS_ARMV8_CRC detection now works fine
# under cross-compilation) or any other patch. Liburing stays Linux-only,
# both via the script's `${target}` check above and via the Dependency's own
# `platforms=linux_platforms` restriction below.
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> arch(p) ∉ ("armv7l", "armv6l"), platforms)

linux_platforms = filter(Sys.islinux, platforms)

# The products that we will ensure are always built.
# On Windows, RocksDB's CMakeLists.txt only applies `OUTPUT_NAME "rocksdb"` to
# the shared-lib target in its non-Windows branch; on Windows the target keeps
# its literal CMake target name `rocksdb-shared`, producing
# `librocksdb-shared.dll` instead of `librocksdb.dll`. Give both names so the
# product check succeeds on every platform without patching upstream CMake.
products = [
    LibraryProduct(["librocksdb", "librocksdb-shared"], :librocksdb),
]

# Dependencies that must be installed before this package can be built.
# Compression libraries are required everywhere; liburing is Linux-only
# (see script above).
dependencies = [
    Dependency(PackageSpec(name="snappy_jll", uuid="fe1e1685-f7be-5f59-ac9f-4ca204017dfd")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Bzip2_jll", uuid="6e34b625-4abd-537c-b88f-471c36dfa7a0")),
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147")),
    Dependency(PackageSpec(name="Zstd_jll", uuid="3161d3a3-bdf6-5164-811a-617609db77b4")),
    Dependency(PackageSpec(name="Liburing_jll", uuid="6524598b-69a8-53ae-b017-622bece5ca95");
               platforms=linux_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"12")
