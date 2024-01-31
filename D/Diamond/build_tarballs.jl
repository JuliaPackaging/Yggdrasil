using BinaryBuilder, Pkg

name = "Diamond"
version = v"2.1.9"

# url = "https://github.com/bbuchfink/diamond"
# description = "Accelerated BLAST-compatible local sequence aligner"

# TODO
# - WITH_AVX512
# - build failures
#   - x86_64-w64-mingw32-cxx11
#     error during compilation: unknown identifier __cpuidex

sources = [
    GitSource("https://github.com/bbuchfink/diamond.git",
              "ba088282666c06db0665dafc4851df45eae701f6"),
]

script = raw"""
cd $WORKSPACE/srcdir/diamond*
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DWITH_ZSTD=ON \
    -DZSTD_LIBRARY="${libdir}/libzstd.${dlext}"
make -j${nproc}
make install
install_license ../LICENSE
"""

platforms = supported_platforms(exclude = p -> Sys.iswindows(p) || nbits(p) == 32)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("diamond", :diamond)
]

dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
