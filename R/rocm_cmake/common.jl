const NAME = "rocm_cmake"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocm-cmake/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "299e190ec3d38c2279d9aec762469628f0b2b1867adc082edc5708d1ac785c3b",
    v"4.5.2" => "85f2ef51327e4b09d81a221b4ad31c97923dabc1bc8ff127dd6c570742185751",
    v"5.2.3" => "c63b707ec07d24fda5a2a6fffeda4df4cc04ceea5df3b8822cbe4e6600e358b4")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11")]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/rocm-cmake*/LICENSE
"""

const PRODUCTS = [FileProduct("share/rocm/cmake", :cmake_dir)]

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, []
end
