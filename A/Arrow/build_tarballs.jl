# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
version = v"10.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/apache/arrow/archive/refs/tags/apache-arrow-$(version).zip",
                  "42995abe620c41c42b8fbc486f1c63a1e5b1da534718ac66dbc790a88efeaa37")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/arrow-apache-arrow-*

# Set toolchain for building external deps
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

cd cpp && mkdir build_dir && cd build_dir

# Ignore check for availibility on older macOS versions
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DARROW_CXXFLAGS="${CXXFLAGS}"
-DCMAKE_BUILD_TYPE=Release
-DARROW_BUILD_UTILITIES=OFF
-DARROW_WITH_UTF8PROC=OFF
-DARROW_DEPENDENCY_SOURCE=SYSTEM
-DARROW_VERBOSE_THIRDPARTY_BUILD=ON
-DARROW_BUILD_STATIC=OFF
-DARROW_DATASET=ON
-DARROW_COMPUTE=OFF
-DARROW_WITH_RE2=OFF
-DARROW_WITH_BZ2=ON
-DARROW_IPC=OFF
-DARROW_WITH_LZ4=ON
-DARROW_WITH_ZSTD=OFF
-DARROW_WITH_ZLIB=ON
-DARROW_WITH_SNAPPY=ON
-DARROW_THRIFT_USE_SHARED=ON
-DARROW_PARQUET=ON
-DPARQUET_BUILD_EXECUTABLES=OFF
-DARROW_SIMD_LEVEL=NONE
-DARROW_USE_XSIMD=OFF
-DARROW_JEMALLOC=OFF
-Dxsimd_SOURCE=AUTO)

cmake .. "${CMAKE_FLAGS[@]}"

make -j${nproc}

make install
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
    Dependency("boost_jll", compat="=1.76.0")
    Dependency("Zlib_jll")
    Dependency("Bzip2_jll", compat="1.0.8")
    Dependency("Lz4_jll")
    Dependency("Thrift_jll")
    Dependency("snappy_jll")
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
