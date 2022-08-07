using Pkg
using BinaryBuilder

name = "rocm_cmake"
version = v"4.5.2"

sources = [
    ArchiveSource(
        "https://github.com/RadeonOpenCompute/rocm-cmake/archive/rocm-$(version).tar.gz",
        "85f2ef51327e4b09d81a221b4ad31c97923dabc1bc8ff127dd6c570742185751"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make -j${nproc}
make install
"""

platforms = [Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11")]
products = [FileProduct("share/rocm/cmake", :cmake_dir)]
dependencies = []

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"7", preferred_llvm_version=v"9", julia_compat="1.8")
