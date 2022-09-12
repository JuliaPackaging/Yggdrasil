const NAME = "ROCmDeviceLibs"

const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "34a2ac39b9bb7cfa8175cbab05d30e7f3c06aaffce99eed5f79c616d0f910f5f",
    v"4.5.2" => "50e9e87ecd6b561cad0d471295d29f7220e195528e567fcabe2ec73838979f61",
    v"5.2.3" => "16b7fc7db4759bd6fb54852e9855fa16ead76c97871d7e1e9392e846381d611a")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
mkdir build && cd build

CC=${WORKSPACE}/srcdir/rocm-clang \
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
        ArchiveSource(
            ROCM_GIT * "/archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
        DirectorySource("../scripts"),
    ]
    DEV_DIR = "/home/pxl-th/.julia/dev/"
    dependencies = [
        # BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(;
            name="ROCmLLVM_jll", version,
            path=joinpath(DEV_DIR, "ROCmLLVM_jll"))),
        BuildDependency(PackageSpec(;
            name="rocm_cmake_jll", version,
            path=joinpath(DEV_DIR, "rocm_cmake_jll"))),
        Dependency("Zlib_jll"),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
