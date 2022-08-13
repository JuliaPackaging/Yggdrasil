const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCm-Device-Libs/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "34a2ac39b9bb7cfa8175cbab05d30e7f3c06aaffce99eed5f79c616d0f910f5f",
    v"4.5.2" => "50e9e87ecd6b561cad0d471295d29f7220e195528e567fcabe2ec73838979f61")
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/ROCm-Device-Libs*/
mkdir build && cd build

cmake \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    ..

make -j${nproc}
make install
"""

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "/archive/rocm-$(version).tar.gz",
            ROCM_TAGS[version]),
    ]
    products = [FileProduct("amdgcn/bitcode/", :bitcode_path)]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        Dependency("Zlib_jll"),
    ]
    name = "ROCmDeviceLibs"
    (
        name, version, sources, BUILDSCRIPT,
        ROCM_PLATFORMS, products, dependencies)
end
