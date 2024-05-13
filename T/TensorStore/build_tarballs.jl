# Note that this script can accept some limited command-line arguments,
# run `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TensorStore"
version = v"0.1.59"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/google/tensorstore", "825f35e67f50103b5906dd6ee0d78c1dded00455"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/tensorstore

# mkdir ${WORKSPACE}/bin
# ln -s ${prefix}/bin/cmake ${WORKSPACE}/bin/cmake
# ln -s ${prefix}/bin/protoc ${WORKSPACE}/bin/protoc
# ln -s ${prefix}/bin/protoc ${WORKSPACE}/bin/protobuf::protoc
# export PATH=${WORKSPACE}/bin:${PATH}

export PATH=${host_bindir}:${PATH}
ln -s ${WORKSPACE}/bin/protoc ${WORKSPACE}/bin/protobuf::protoc

# TensorStore builds some vendored other packages. We have basically
# no control over this. We use `ccsafe` etc. to avoid problems with
# `-ffast-math` etc.
sed -i -e 's!set(CMAKE_C_COMPILER.*!set(CMAKE_C_COMPILER '${WORKSPACE}/srcdir/files/ccsafe')!' ${CMAKE_TARGET_TOOLCHAIN}
sed -i -e 's!set(CMAKE_CXX_COMPILER.*!set(CMAKE_CXX_COMPILER '${WORKSPACE}/srcdir/files/c++safe')!' ${CMAKE_TARGET_TOOLCHAIN}

cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    \
    -DTENSORSTORE_USE_SYSTEM_ABSL=OFF \
    -DTENSORSTORE_USE_SYSTEM_BLOSC=ON \
    -DTENSORSTORE_USE_SYSTEM_BROTLI=ON \
    -DTENSORSTORE_USE_SYSTEM_BZIP2=ON \
    -DTENSORSTORE_USE_SYSTEM_CURL=ON \
    -DTENSORSTORE_USE_SYSTEM_C_ARES=ON \
    -DTENSORSTORE_USE_SYSTEM_JPEG=ON \
    -DTENSORSTORE_USE_SYSTEM_LIBLZMA=ON \
    -DTENSORSTORE_USE_SYSTEM_LZ4=ON \
    -DTENSORSTORE_USE_SYSTEM_NGHTTP2=ON \
    -DTENSORSTORE_USE_SYSTEM_NLOHMANN_JSON=ON \
    -DTENSORSTORE_USE_SYSTEM_OPENSSL=ON \
    -DTENSORSTORE_USE_SYSTEM_PNG=ON \
    -DTENSORSTORE_USE_SYSTEM_PROTOBUF=OFF \
    -DTENSORSTORE_USE_SYSTEM_SNAPPY=ON \
    -DTENSORSTORE_USE_SYSTEM_TIFF=ON \
    -DTENSORSTORE_USE_SYSTEM_TINYXML2=OFF \
    -DTENSORSTORE_USE_SYSTEM_WEBP=ON \
    -DTENSORSTORE_USE_SYSTEM_ZLIB=ON \
    -DTENSORSTORE_USE_SYSTEM_ZSTD=ON \

# option(TENSORSTORE_USE_SYSTEM_BLAKE3 "Use an installed version of BLAKE3")
# option(TENSORSTORE_USE_SYSTEM_UDPA "Use an installed version of udpa")
# option(TENSORSTORE_USE_SYSTEM_BENCHMARK "Use an installed version of benchmark")
# option(TENSORSTORE_USE_SYSTEM_GOOGLEAPIS "Use an installed version of Googleapis")
# option(TENSORSTORE_USE_SYSTEM_GTEST "Use an installed version of GTest")
# option(TENSORSTORE_USE_SYSTEM_LIBYUV "Use an installed version of libyuv")
# option(TENSORSTORE_USE_SYSTEM_UTF8_RANGE "Use an installed version of utf8_range")
# option(TENSORSTORE_USE_SYSTEM_RE2 "Use an installed version of Re2")
# option(TENSORSTORE_USE_SYSTEM_RIEGELI "Use an installed version of riegeli")
# option(TENSORSTORE_USE_SYSTEM_ENVOY "Use an installed version of envoy")
# option(TENSORSTORE_USE_SYSTEM_HALF "Use an installed version of half")
# option(TENSORSTORE_USE_SYSTEM_AOM "Use an installed version of aom")
# option(TENSORSTORE_USE_SYSTEM_AVIF "Use an installed version of AVIF")
# option(TENSORSTORE_USE_SYSTEM_DAV1D "Use an installed version of dav1d")

cmake --build build --parallel ${nproc}
cmake --install build
install_license Copyright.txt LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# TODO
platforms = [
    Pkg.BinaryPlatforms.Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")
]

# The products that we will ensure are always built
products = [
    # TODO: correct products
    LibraryProduct("tensorstore", :tensorstore),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # TODO: add compat versions
    HostBuildDependency(PackageSpec("CMake_jll", v"3.24.3")), # we need 3.24
    HostBuildDependency(PackageSpec("protoc_jll", v"26.1")),
    Dependency("Blosc_jll"),
    Dependency("Bzip2_jll"),
    Dependency("Cares_jll"),
    Dependency("JpegTurbo_jll"),
    Dependency("LibCURL_jll"),
    Dependency("Libtiff_jll"),
    Dependency("Lz4_jll"),
    Dependency("NASM_jll"),
    Dependency("OpenSSL_jll"; compat="3.0.8"),
    # Dependency("TinyXML_jll"),
    Dependency("XZ_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    # Dependency("abseil_cpp_jll"),
    Dependency("brotli_jll"),
    Dependency("libpng_jll"),
    Dependency("libwebp_jll"),
    Dependency("nghttp2_jll"),
    Dependency("nlohmann_json_jll"),
    Dependency("snappy_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
