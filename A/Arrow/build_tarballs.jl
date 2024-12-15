# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
# This installs Arrow 18.1.0.
# We declare this as 18.1.1 because we enabled the Zstd library, changing the package dependencies.
version = v"18.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/arrow.git",
              "6a0414bd9a91e890ec6a45369bf61f405180628c"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/arrow

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/boost.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows.patch
if [[ $target == *mingw32* ]]; then
    # This hard-codes the name and location of the zstd library and
    # must not be applied on other architectures
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows-zstd.patch
fi

cd cpp

CMAKE_FLAGS=(
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DARROW_BUILD_STATIC=OFF
    -DARROW_BUILD_UTILITIES=OFF
    -DARROW_COMPUTE=OFF
    -DARROW_CXXFLAGS="${CXXFLAGS}"
    -DARROW_DATASET=ON
    -DARROW_DEPENDENCY_SOURCE=SYSTEM
    -DARROW_IPC=OFF
    -DARROW_JEMALLOC=OFF
    -DARROW_PARQUET=ON
    -DARROW_SIMD_LEVEL=NONE
    -DARROW_THRIFT_USE_SHARED=ON
    -DARROW_USE_XSIMD=OFF
    -DARROW_VERBOSE_THIRDPARTY_BUILD=ON
    -DARROW_WITH_BROTLI=ON
    -DARROW_WITH_BZ2=ON
    -DARROW_WITH_LZ4=ON
    -DARROW_WITH_RE2=OFF
    -DARROW_WITH_SNAPPY=ON
    -DARROW_WITH_UTF8PROC=OFF
    -DARROW_WITH_ZLIB=ON
    -DARROW_WITH_ZSTD=ON
    -DPARQUET_BUILD_EXECUTABLES=OFF
    -Dxsimd_SOURCE=AUTO
)

if [[ $target == *mingw32* ]]; then
    # Cmake doesn't find the zstd library on Windows. It does find
    # zstd, but it somehow can't determine the path to the actual
    # library.
    CMAKE_FLAGS+=(-DZSTD_LIB=/workspace/destdir/lib/libzstd.dll.a)
fi

cmake -B cmake-build "${CMAKE_FLAGS[@]}"
cmake --build cmake-build --parallel ${nproc}
cmake --install cmake-build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libparquet", :libparquet),
    LibraryProduct("libarrow", :libarrow),
    LibraryProduct("libarrow_dataset", :libarrow_dataset),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8"),
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    Dependency("Lz4_jll"),
    Dependency("Thrift_jll"; compat="0.21"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.6"),
    Dependency("boost_jll"; compat="=1.79.0"),
    Dependency("brotli_jll"; compat="1.1.0"),
    Dependency("snappy_jll"; compat="1.2.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
