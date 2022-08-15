const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocm-cmake/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "299e190ec3d38c2279d9aec762469628f0b2b1867adc082edc5708d1ac785c3b",
    v"4.5.2" => "85f2ef51327e4b09d81a221b4ad31c97923dabc1bc8ff127dd6c570742185751",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*/

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make -j${nproc}
make install
"""

const PRODUCTS = [FileProduct("share/rocm/cmake", :cmake_dir)]
const NAME = "rocm_cmake"

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, []
end
