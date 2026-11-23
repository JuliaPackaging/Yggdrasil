# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PFFFT"
version = v"1.3.1"

sources = [
    GitSource("https://github.com/marton78/pffft.git", "fbe9c2b96530ce274f12e008336a8202e15b859b"; tag="v$(version)"),
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
    -DPFFFT_BUILD_TESTS=OFF \
    -DPFFFT_BUILD_BENCHMARKS=OFF \
    -DPFFFT_BUILD_EXAMPLES=OFF
# Only libpffft is shipped. The C++ PFDSP library, built by default, fails on x86 musl,
# where GCC 4.8.5's mm_malloc.h clashes with musl's posix_memalign
cmake --build build --parallel ${nproc} --target PFFFT
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

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
