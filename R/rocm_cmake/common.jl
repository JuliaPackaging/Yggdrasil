const NAME = "rocm_cmake"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/rocm-cmake.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "cf7fac0b00d4a18f00e391b7f5086b1a910c5f33",
    v"4.5.2" => "8d82398d269d993872be5be319621fad5bf7d59c",
    v"5.2.3" => "5022bb7778cffada15416e32f8bc339d71ea0534",
    v"5.4.4" => "88fd446cdbdd4ae5d902b1be6d380eebecd15be2",
    v"5.5.1" => "2e823f7604a965e7d56cff48d58fb666354bbfeb",
    v"5.6.1" => "07ec4c536108ae943e37985915ef279529ac693f",
    v"5.7.1" => "15cbb2e47f0b9ec758d89227f20ef3b4b23aa723",
    v"6.0.0" => "5a34e72d9f113eb5d028e740c2def1f944619595")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11")]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/rocm-cmake*

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}

cmake --build build --parallel ${nproc}
cmake --install build

install_license ${WORKSPACE}/srcdir/rocm-cmake*/LICENSE
"""

const PRODUCTS = [FileProduct("share/rocm/cmake", :cmake_dir)]

function configure_build(version)
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, []
end
