const NAME = "rocm_cmake"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocm-cmake.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "cf7fac0b00d4a18f00e391b7f5086b1a910c5f33",
    v"4.5.2" => "8d82398d269d993872be5be319621fad5bf7d59c",
    v"5.2.3" => "5022bb7778cffada15416e32f8bc339d71ea0534",
    v"5.4.4" => "2e823f7604a965e7d56cff48d58fb666354bbfeb")
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
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, []
end
