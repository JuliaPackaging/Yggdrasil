const NAME = "ROCmDeviceLibs"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs.git"
const ROCM_TAGS = Dict(
    v"4.2.0" => "e54681814f72a3657c428f12c9ae0561db7f2972",
    v"4.5.2" => "0f2eb8c16630c1f03a417c7a4248402c356ee510",
    v"5.2.3" => "d999f1780979585119251d4e90c923133a775a8c",
    v"5.4.4" => "4d86a313a33027cff82dc73fe9b8395a7a96eb04",
    v"5.5.1" => "49dd756ee374d648beb3ecd593f419db425ef621")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
mkdir build && cd build

CC=${WORKSPACE}/srcdir/rocm-clang \
CXX=${WORKSPACE}/srcdir/rocm-clang++ \
cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_DIR=${prefix}/llvm/lib/cmake/llvm \
    -DLLD_DIR=${prefix}/llvm/lib/cmake/lld \
    -DClang_DIR=${prefix}/llvm/lib/cmake/clang \
    ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/ROCm-Device-Libs*/LICENSE.TXT
"""

const PRODUCTS = [FileProduct("amdgcn/bitcode/", :bitcode_path)]

function configure_build(version)
    sources = [
        GitSource(ROCM_GIT, ROCM_TAGS[version]),
        DirectorySource("../scripts"),
    ]
    # Compile devlibs with older LLVM version than what's used in ROCmLLVM
    # for Julia compatibility.
    llvm_version = min(v"5.4.4", version)
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=llvm_version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("Zlib_jll"),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
