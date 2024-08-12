const NAME = "ROCmCompilerSupport"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport.git"
const GIT_TAGS = Dict(
    v"4.2.0" => "f3e81459441fd60dcb5b5e547b637c474892aa4f",
    v"4.5.2" => "9fc2026bb43aa0f5cf989ca1b077822bd8d18240",
    v"5.2.3" => "196e2d0e20e32752ea46a361618f05cf8af5c61f",
    v"5.4.4" => "be624c66c58a5ff60081538dff70a235248a8131",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCm-CompilerSupport*/lib/comgr

mkdir build && cd build

CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DLLVM_DIR=${prefix}/llvm/lib/cmake/llvm \
      -DLLD_DIR=${prefix}/llvm/lib/cmake/lld \
      -DClang_DIR=${prefix}/llvm/lib/cmake/clang \
      -DROCM_DIR=${prefix} \
      -DBUILD_TESTING:BOOL=OFF \
      ..

make -j${nproc}
make install

install_license ${WORKSPACE}/srcdir/ROCm-CompilerSupport*/LICENSE.txt
"""

const PRODUCTS = [LibraryProduct(["libamd_comgr"], :libamd_comgr)]

function configure_build(version)
    sources = [
        GitSource(ROCM_GIT, GIT_TAGS[version]),
        DirectorySource("../scripts"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("ROCmDeviceLibs_jll"; compat=string(version)),
        Dependency("hsa_rocr_jll"; compat=string(version)),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
