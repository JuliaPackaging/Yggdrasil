# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Arrow"
version = v"9.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/apache/arrow/archive/refs/tags/apache-arrow-9.0.0.zip", "fb2469e9bfeb3e9a45f1e3086f536a329d59a0efd3c905436d3b6e8dd030be41")
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

CMAKE_FLAGS=(-DCMAKE_INSTALL_PREFIX=$prefix
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
-DCMAKE_BUILD_TYPE=Release
-DARROW_BUILD_UTILITIES=ON
-DARROW_DEPENDENCY_SOURCE=SYSTEM
-DARROW_BUILD_STATIC=OFF
-DARROW_DATASET=ON
-DARROW_WITH_BZ2=ON
-DARROW_WITH_LZ4=ON
-DARROW_WITH_ZSTD=ON
-DARROW_WITH_ZLIB=ON
-DARROW_WITH_SNAPPY=ON
-DARROW_JEMALLOC_USE_SHARED=ON
-DARROW_PARQUET=ON
-DARROW_SIMD_LEVEL=NONE
-DARROW_USE_XSIMD=OFF
-Dxsimd_SOURCE=AUTO
-Dre2_SOURCE=AUTO)

echo $CMAKE_FLAGS

# CMake is doubling the suffixes...
if [[ "${target}" == *-mingw32 ]]; then
    ln -s ${prefix}/lib/libthrift.dll.a ${prefix}/lib/libthrift.a.dll.a
    ln -s ${prefix}/lib/libutf8proc.a ${prefix}/lib/libutf8proc.dll.a.a
fi

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
    LibraryProduct("libarrow", :libarrow)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll", compat="=1.76.0")
    Dependency("Zlib_jll")
    Dependency("Bzip2_jll", compat="1.0.7")
    Dependency("Zstd_jll")
    Dependency("Lz4_jll")
    Dependency("jemalloc_jll")
    Dependency("Thrift_jll")
    Dependency("snappy_jll")
    Dependency("utf8proc_jll")
    Dependency("RE2_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
