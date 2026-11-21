# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PFFFT"
version = v"1.3.1"

# PFFFT: a fast FFT for real and complex data of power-of-two (and 2^a·3^b·5^c) lengths, SIMD on
# SSE, NEON and AltiVec, single and double precision, BSD-style licence (FFTPACK's).
sources = [
    GitSource("https://github.com/marton78/pffft.git", "fbe9c2b96530ce274f12e008336a8202e15b859b"),
]

script = raw"""
cd $WORKSPACE/srcdir/pffft
# On RISC-V the build adds -march=rv64gcv (the vector extension) by itself, which BinaryBuilder
# does not allow: build for the platform's baseline instead, as on every other target.
# https://github.com/marton78/pffft/issues/120
sed -i 's/if (CMAKE_SYSTEM_PROCESSOR MATCHES "riscv64")/if (FALSE)/' cmake/target_optimizations.cmake
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DPFFFT_USE_TYPE_FLOAT=ON \
    -DPFFFT_USE_TYPE_DOUBLE=ON \
    -DPFFFT_USE_SIMD=ON \
    -DPFFFT_BUILD_TESTS=OFF \
    -DPFFFT_BUILD_BENCHMARKS=OFF \
    -DPFFFT_BUILD_EXAMPLES=OFF \
    -DPFFFT_USE_FFTPACK=OFF \
    -DPFFFT_USE_BENCH_GREEN=OFF \
    -DPFFFT_USE_BENCH_KISS=OFF \
    -DPFFFT_USE_BENCH_POCKET=OFF \
    -DINSTALL_PFFFT=ON \
    -DINSTALL_PFDSP=OFF \
    -DINSTALL_PFFASTCONV=OFF
cmake --build build --parallel ${nproc}
cmake --install build
# The install rule has no RUNTIME destination, so on Windows the DLL itself is not installed
# https://github.com/marton78/pffft/issues/119
if [[ "${target}" == *-mingw* ]]; then
    install -Dvm 755 build/libpffft.dll "${libdir}/libpffft.dll"
fi
install_license LICENSE.txt
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libpffft", :libpffft),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
