# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZlibNG"
version = v"2.3.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zlib-ng/zlib-ng.git", "12731092979c6d07f42da27da673a9f6c7b13586"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib-ng

# Architecture-specific optimization flags
# These default to ON in zlib-ng, but we set them explicitly to ensure
# they are not missed during cross-compilation.
# We also force-set compiler flag variables and detection results because
# cmake's check_c_compiler_flag tests fail during cross-compilation.
# On aarch64, NEON is always available so no special compiler flag is needed,
# but BinaryBuilder rejects -march flags, so we patch the cmake detection
# to use empty flags instead.
CMAKE_EXTRA_OPTIONS=(
    -DWITH_RUNTIME_CPU_DETECTION=ON
)
if [[ "${target}" == aarch64-* ]]; then
    # Patch cmake detection to avoid -march flags that BinaryBuilder rejects.
    # NEON and CRC32 are always available on aarch64, no special flag needed.
    sed -i 's/-march=armv8-a+simd//g' cmake/detect-intrinsics.cmake
    sed -i 's/-march=armv8-a+crc+simd//g' cmake/detect-intrinsics.cmake
    sed -i 's/-march=armv8-a+crc//g' cmake/detect-intrinsics.cmake
    CMAKE_EXTRA_OPTIONS+=(
        -DWITH_NEON=ON
        -DWITH_ARMV8=ON
    )
elif [[ "${target}" == x86_64-* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        -DWITH_SSE2=ON
        -DWITH_SSSE3=ON
        -DWITH_SSE41=ON
        -DWITH_SSE42=ON
        -DWITH_PCLMULQDQ=ON
        -DWITH_AVX2=ON
        -DWITH_AVX512=ON
        -DWITH_AVX512VNNI=ON
        -DWITH_VPCLMULQDQ=ON
    )
elif [[ "${target}" == powerpc64le-* ]]; then
    CMAKE_EXTRA_OPTIONS+=(
        -DWITH_ALTIVEC=ON
        -DWITH_POWER8=ON
        -DWITH_POWER9=ON
    )
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    "${CMAKE_EXTRA_OPTIONS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libz-ng", "libzlib-ng2"], :libzng)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"11")
