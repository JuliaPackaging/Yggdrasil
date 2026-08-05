using BinaryBuilder

name = "libCZI"
version = v"0.69.1"

sources = [
    GitSource(
        "https://github.com/ZEISS/libczi.git",
        "61f74ff097d6d0fbe6e36f204ff59d92e299d7cd",
    ),
]

script = raw"""
cd "${WORKSPACE}/srcdir/libczi"

# Zstd_jll installs pkg-config metadata, whereas libCZI expects a
# CMake config package. Use the pkg-config target directly.
sed -i \
    '/find_package(zstd CONFIG REQUIRED)/,/^  endif()$/c\
  find_package(PkgConfig REQUIRED)\
  pkg_check_modules(ZSTD REQUIRED IMPORTED_TARGET libzstd)\
  set(LIBCZI_ZSTD_LINK_TARGET "PkgConfig::ZSTD")' \
    Src/libCZI/CMakeLists.txt

if [[ "${target}" == *-mingw* ]]; then
    # MinGW resolves headers and import libraries through a
    # case-sensitive cross-compilation filesystem.
    find Src -type f \( -name '*.h' -o -name '*.hpp' -o -name '*.cpp' \) \
        -exec sed -i 's/<Windows\.h>/<windows.h>/g' {} +

    sed -i \
        's/ole32 Windowscodecs/ole32 windowscodecs/g' \
        Src/libCZI/CMakeLists.txt
fi

cmake_options=()

# Upstream uses try_run() to test NEON support, which cannot execute
# while cross-compiling. Advanced SIMD is part of AArch64.
if [[ "${target}" == aarch64-* ]]; then
    cmake_options+=("-DNEON_INTRINSICS_CAN_BE_USED=TRUE")
fi

atomic_libraries=""
if [[ "${target}" == riscv64-* ]]; then
    atomic_libraries="atomic"
fi

cmake -S . -B build \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCRASH_ON_UNALIGNED_ACCESS=ON \
    -DADDITIONAL_LIBS_REQUIRED_FOR_ATOMIC="${atomic_libraries}" \
    -DLIBCZI_BUILD_UNITTESTS=OFF \
    -DLIBCZI_BUILD_CZICMD=OFF \
    -DLIBCZI_BUILD_DYNLIB=OFF \
    -DLIBCZI_ENABLE_INSTALL=OFF \
    -DLIBCZI_BUILD_LIBCZIAPI=ON \
    -DLIBCZI_BUILD_CURL_BASED_STREAM=OFF \
    -DLIBCZI_BUILD_AZURESDK_BASED_STREAM=OFF \
    -DLIBCZI_BUILD_ENABLE_EXPERIMENTAL_FUNCTIONALITY=OFF \
    -DLIBCZI_BUILD_PREFER_EXTERNALPACKAGE_EIGEN3=ON \
    -DLIBCZI_BUILD_PREFER_EXTERNALPACKAGE_ZSTD=ON \
    -DLIBCZI_BUILD_PREFER_EXTERNALPACKAGE_RAPIDJSON=ON \
    -DLIBCZI_DESTINATION_FOLDER_LIBCZIAPI="${libdir}" \
    "${cmake_options[@]}"

cmake --build build \
    --target libCZIAPI \
    --parallel "${nproc}"

mkdir -p "${includedir}/libCZIAPI"
cp -a Src/libCZIAPI/inc/. "${includedir}/libCZIAPI/"

install_license \
    COPYING \
    THIRD_PARTY_LICENSES.txt
"""

# Exclude architectures outside libCZI's supported 64-bit build matrix.
platforms = supported_platforms(
    exclude=p -> arch(p) ∈ ("i686", "armv6l", "armv7l"),
)

# Required by BinaryBuilder's audit because the library contains
# externally visible std::string ABI usage.
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct(
        ["liblibCZIAPI", "libCZIAPI"],
        :libCZIAPI,
    ),
    FileProduct(
        "include/libCZIAPI/libCZIApi.h",
        :libCZIApi_h,
    ),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency("rapidjson_jll"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"10",
    julia_compat="1.6",
)

