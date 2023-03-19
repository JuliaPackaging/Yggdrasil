using BinaryBuilder, Pkg

name = "Diamond"
version = v"2.1.6"

# url = "https://github.com/bbuchfink/diamond"
# description = "Accelerated BLAST-compatible local sequence aligner"

# TODO
# - WITH_ZSTD (fails to find the library)
# - WITH_AVX512
# - build failures
#   - x86_64-w64-mingw32-cxx11
#     error during compilation: unknown identifier __cpuidex

sources = [
    # v2.1.6
    GitSource("https://github.com/bbuchfink/diamond/",
              "0540f86d3d5965cf9a6ef8871068999ef61211dc";
              unpack_target="diamond"),
]

script = raw"""
cd $WORKSPACE/srcdir/diamond*
mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=RELEASE
make -j${nproc}
make install
install_license ../LICENSE
"""

platforms = supported_platforms(exclude = p -> Sys.iswindows(p))
platforms = expand_cxxstring_abis(platforms; skip = p -> Sys.isfreebsd(p) || (Sys.isapple(p) && arch(p) == "aarch64"))

products = [
    ExecutableProduct("diamond", :diamond)
]

dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
