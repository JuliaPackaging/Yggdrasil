const NAME = "ROCmCompilerSupport"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-CompilerSupport/"
const GIT_TAGS = Dict(
    v"4.2.0" => "40a1ea50d2aea0cf75c4d17cdd6a7fe44ae999bf0147d24a756ca4675ce24e36",
    v"4.5.2" => "e45f387fb6635fc1713714d09364204cd28fea97655b313c857beb1f8524e593",
    v"5.2.3" => "36d67dbe791d08ad0a02f0f3aedd46059848a0a232c5f999670103b0410c89dc",
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
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
        DirectorySource("../scripts"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("hsa_rocr_jll", version),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
