const ROCM_GIT = "https://github.com/RadeonOpenCompute/ROCR-Runtime/"
const ROCM_TAGS = Dict(
    v"4.2.0" => "fa0e7bcd64e97cbff7c39c9e87c84a49d2184dc977b341794770805ec3f896cc",
    v"4.5.2" => "d99eddedce0a97d9970932b64b0bb4743e47d2740e8db0288dbda7bec3cefa80",
    v"5.2.3" => "978de85d3455207bb82bef2254a4624e9116b1258a8c164d7a7e21a644eff12f",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
const PATCHES = Dict(
    v"4.2.0" => raw"""
    atomic_patch -p1 ../patches/1-no-werror.patch
    """,
    v"4.5.2" => raw"""
    atomic_patch -p1 ../patches/1-no-werror.patch
    atomic_patch -p1 ../patches/musl-affinity.patch
    """,
    v"5.2.3" => raw"""
    atomic_patch -p1 ../patches/musl-affinity.patch
    atomic_patch -p1 ../patches/musl-pthread-rwlock.patch
    """,
)

const PRODUCTS = [LibraryProduct(["libhsa-runtime64"], :libhsa_runtime64)]
const NAME = "hsa_rocr"

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/ROCR-Runtime*/
    """ *
    PATCHES[version] *
    raw"""
    mkdir build && cd build

    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DBITCODE_DIR=${prefix}/amdgcn/bitcode \
        ../src

    make -j${nproc}
    make install
    install_license ${WORKSPACE}/srcdir/ROCR-Runtime*/LICENSE.txt
    """
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", ROCM_TAGS[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("NUMA_jll"),
        Dependency("XML2_jll"),
        Dependency("Elfutils_jll"),
    ]
    if version < v"5"
        # 1.2.12 causes undefined variable errors:
        # https://github.com/JuliaPackaging/Yggdrasil/pull/5367
        push!(dependencies, Dependency("Zlib_jll", v"1.2.11"))
    else
        push!(dependencies, Dependency("Zlib_jll"))
    end
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
