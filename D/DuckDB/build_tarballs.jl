# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include("../../platforms/macos_sdks.jl")

name = "DuckDB"
version = v"1.5.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/duckdb/duckdb.git", "d8cdaa33fda8df955cc76ef58a280f68f4cd43fa"),
    # The excel extension lives out-of-tree; this is the commit duckdb v1.5.5
    # pins in .github/config/extensions/excel.cmake
    GitSource("https://github.com/duckdb/duckdb-excel.git", "f4c72b5ef04a03b3a78a95b5a2ee94ba93e3178d"),
    # minizip-ng 4.0.7, the version duckdb-excel's vcpkg manifest pins
    GitSource("https://github.com/zlib-ng/minizip-ng.git", "fe5fedc365f7824ada0cf9a84fb79b30d5fc97a8"),
]

# Bash recipe for building across all platforms
script = raw"""
# Static minizip-ng for the excel extension (there is no minizip-ng JLL); it is
# absorbed into libduckdb, so nothing from it ships in the tarball.
cmake -S $WORKSPACE/srcdir/minizip-ng -B $WORKSPACE/srcdir/minizip-build \
      -DCMAKE_INSTALL_PREFIX=$WORKSPACE/deps \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DMZ_LIB_SUFFIX=-ng \
      -DMZ_FETCH_LIBS=OFF \
      -DMZ_ZLIB=ON \
      -DZLIB_ROOT=${prefix} \
      -DMZ_BZIP2=OFF \
      -DMZ_LZMA=OFF \
      -DMZ_ZSTD=OFF \
      -DMZ_OPENSSL=OFF \
      -DMZ_LIBBSD=OFF \
      -DMZ_ICONV=OFF \
      -DMZ_PKCRYPT=OFF \
      -DMZ_WZAES=OFF \
      -DMZ_LIBCOMP=OFF \
      -DMZ_BUILD_TESTS=OFF
# minizip-ng silently disables deflate when it fails to find zlib, which breaks
# every read_xlsx/write at runtime — fail the build instead
if grep -rq "MZ_ZIP_NO_COMPRESSION" $WORKSPACE/srcdir/minizip-build/CMakeFiles/*.dir/flags.make; then
    echo "ERROR: minizip-ng configured without zlib (no compression support)" >&2
    exit 1
fi

cmake --build $WORKSPACE/srcdir/minizip-build --parallel ${nproc}
cmake --install $WORKSPACE/srcdir/minizip-build

# Out-of-tree extension config. The stock .github/config/extensions/excel.cmake
# would git-clone at configure time; this loads the pre-fetched source instead.
# excel must NOT also appear in BUILD_EXTENSIONS, or the stock config wins.
cat > $WORKSPACE/srcdir/extension_config.cmake <<EOF
duckdb_extension_load(excel
    SOURCE_DIR $WORKSPACE/srcdir/duckdb-excel
    INCLUDE_DIR $WORKSPACE/srcdir/duckdb-excel/src/excel/include
    EXTENSION_VERSION f4c72b5
)
EOF

cd $WORKSPACE/srcdir/duckdb/

export DUCKDB_TARGET="${target}"
if [[ "${target}" == "x86_64-linux-gnu" ]]; then
    export DUCKDB_TARGET="linux_amd64"
elif [[ "${target}" == aarch64-linux-gnu ]]; then
    export DUCKDB_TARGET="linux_arm64"
elif [[ "${target}" == "x86_64-linux-musl" ]]; then
    export DUCKDB_TARGET="linux_amd64_musl"
elif [[ "${target}" == "x86_64-w64-mingw32" ]]; then
    export DUCKDB_TARGET="windows_amd64_mingw"
elif [[ "${target}" == x86_64-apple-* ]]; then
    export DUCKDB_TARGET="osx_amd64"
elif [[ "${target}" == aarch64-apple-* ]]; then
    export DUCKDB_TARGET="osx_arm64"
fi

if [[ "${bb_full_target}" == *-cxx03* ]]; then
    export DUCKDB_TARGET="${DUCKDB_TARGET}_gcc4"
fi

echo "Compiling for DuckDB Target - $DUCKDB_TARGET"

cmake -B build \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_PREFIX_PATH=$WORKSPACE/deps \
      -DCMAKE_CXX_FLAGS="-I$WORKSPACE/deps/include" \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_SANITIZER=FALSE \
      -DBUILD_EXTENSIONS='parquet;json;icu;autocomplete' \
      -DDUCKDB_EXTENSION_CONFIGS=$WORKSPACE/srcdir/extension_config.cmake \
      -DENABLE_JEMALLOC=OFF \
      -DENABLE_EXTENSION_AUTOLOADING=1 \
      -DENABLE_EXTENSION_AUTOINSTALL=1 \
      -DBUILD_UNITTESTS=FALSE \
      -DBUILD_SHELL=TRUE \
      -DDUCKDB_EXPLICIT_PLATFORM=${DUCKDB_TARGET}
cmake --build build --parallel ${nproc}
cmake --install build

if [[ "${target}" == *-mingw32 ]]; then
    install -Dvm 755 "build/src/libduckdb.${dlext}" -t "${libdir}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
# Building for PowerPC results in errors inside jemalloc:
#     /tmp/ccmHnfhC.s: Assembler messages:
#     /tmp/ccmHnfhC.s:7829: Error: unrecognized opcode: `pause'
#     make[2]: *** [extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/build.make:76: extension/jemalloc/jemalloc/CMakeFiles/jemalloc.dir/src/jemalloc.c.o] Error 1
filter!(p -> arch(p) != "powerpc64le", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libduckdb", :libduckdb),
    ExecutableProduct("duckdb", :duckdb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Needed by the excel extension
    Dependency("Expat_jll"; compat="2.6.5"),
    Dependency("Zlib_jll"),
]

# The default macOS 10.12 SDK (and even 10.15) has a libc++ that doesn't provide
# std::hash for enum types (LWG 2148). Use SDK 14.0 which definitely includes it.
# DuckDB itself targets macOS 11.0, so we set that as the deployment target.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="11.0")

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 10 (not older): the autocomplete extension needs a newer libstdc++ than
# GCC 6.1's, and upstream builds its mingw binaries with GCC 10 as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"10.2.0", julia_compat="1.6")
