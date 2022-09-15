const HIPAMD_GIT = "https://github.com/ROCm-Developer-Tools/hipamd/"
const HIP_GIT = "https://github.com/ROCm-Developer-Tools/HIP/"

# Needed, since ROCclr is no longer can be built as standalone project.
# So we build it here as well as in ROCmOpenCLRuntime.
const ROCM_GIT_CL = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr/"

const HIPAMD_GIT_TAGS = Dict(
    v"4.5.2" => "b6f35b1a1d0c466b5af28e26baf646ae63267eccc4852204db1e0c7222a39ce2",
)
const HIP_GIT_TAGS = Dict(
    v"4.2.0" => "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24",
    v"4.5.2" => "c2113dc3c421b8084cd507d91b6fbc0170765a464b71fb0d96bb875df368f160",
)

const GIT_TAGS_CL = Dict(
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
)
const GIT_TAGS_CLR = Dict(
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

const CLR_CMAKE = Dict(
    v"4.2.0" => "",
    v"4.5.2" => raw"""
    export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
    export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

    cd ${ROCclr_DIR}
    atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch

    mkdir build && cd build
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX=${prefix}/rocclr \
        -DCMAKE_BUILD_TYPE=Release \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        ..
    make -j${nproc} # no install target
    """,
)

const HIP_CMAKE = Dict(
    v"4.2.0" => raw"""
    cd ${WORKSPACE}/srcdir/HIP*/

    # Disable tests.
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"
    atomic_patch -p1 --binary "${WORKSPACE}/srcdir/patches/no-init-abort.patch"
    mkdir build && cd build

    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    CXXFLAGS="-isystem ${prefix}/rocclr/include/elf -isystem ${prefix}/include/elfutils -isystem ${prefix}/rocclr/include/compiler/lib/include $CXXFLAGS " \
    cmake \
        -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DROCM_PATH=${prefix} \
        -DHSA_PATH=${prefix}/hsa \
        -DHIP_PLATFORM=amd \
        -DHIP_RUNTIME=rocclr \
        -DHIP_COMPILER=clang \
        -D__HIP_ENABLE_PCH=OFF \
        -DLLVM_DIR="${prefix}/llvm/lib/cmake/llvm" \
        -DClang_DIR="${prefix}/llvm/lib/cmake/clang" \
        ..
    make -j${nproc}
    make install
    """,
    v"4.5.2" => raw"""
    cd ${WORKSPACE}/srcdir/hipamd*/
    mkdir build && cd build
    export HIP_DIR=$(realpath ${WORKSPACE}/srcdir/HIP-*)

    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    cmake \
        -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
        -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${prefix}" \
        -DROCM_PATH=${prefix} \
        -DHIP_PLATFORM=amd \
        -DHIP_RUNTIME=rocclr \
        -DHIP_COMPILER=clang \
        -D__HIP_ENABLE_PCH=OFF \
        -DROCCLR_INCLUDE_DIR=${ROCclr_DIR}/include \
        -DROCCLR_PATH=${ROCclr_DIR} \
        -DHIP_COMMON_DIR=${HIP_DIR} \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        -DCMAKE_HIP_ARCHITECTURES="gfx906:xnack-" \
        -DLLVM_DIR="${prefix}/llvm/lib/cmake/llvm" \
        -DClang_DIR="${prefix}/llvm/lib/cmake/clang" \
        ..
    make -j${nproc}
    make install
    """
)

const NAME = "HIP"
const PRODUCTS = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

function configure_build(version)
    archive = "archive/rocm-$version.tar.gz"

    sources = [
        ArchiveSource(HIP_GIT * archive, HIP_GIT_TAGS[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    if version == v"4.5.2"
        push!(
            sources,
            ArchiveSource(HIPAMD_GIT * archive, HIPAMD_GIT_TAGS[version]),
            ArchiveSource(ROCM_GIT_CL * "archive/rocm-$(version).tar.gz", GIT_TAGS_CL[version]),
            ArchiveSource(ROCM_GIT_CLR * "archive/rocm-$(version).tar.gz", GIT_TAGS_CLR[version]))
    end

    buildscript =
        CLR_CMAKE[version] *
        HIP_CMAKE[version]

    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("hsakmt_roct_jll", version),
        Dependency("hsa_rocr_jll", version),
        Dependency("rocminfo_jll", version),
        Dependency("ROCmDeviceLibs_jll", version),
        Dependency("ROCmCompilerSupport_jll", version),
        Dependency("ROCmOpenCLRuntime_jll", version),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
