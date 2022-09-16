const NAME = "HIP"

const HIPAMD_GIT = "https://github.com/ROCm-Developer-Tools/hipamd/"
const HIP_GIT = "https://github.com/ROCm-Developer-Tools/HIP/"

# Needed, since ROCclr is no longer can be built as standalone project.
# So we build it here as well as in ROCmOpenCLRuntime.
const ROCM_GIT_CL = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr/"

const HIPAMD_GIT_TAGS = Dict(
    v"4.5.2" => "b6f35b1a1d0c466b5af28e26baf646ae63267eccc4852204db1e0c7222a39ce2",
    v"5.2.3" => "5031d07554ce07620e24e44d482cbc269fa972e3e35377e935d2694061ff7c04",
)
const HIP_GIT_TAGS = Dict(
    v"4.2.0" => "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24",
    v"4.5.2" => "c2113dc3c421b8084cd507d91b6fbc0170765a464b71fb0d96bb875df368f160",
    v"5.2.3" => "5b83d1513ea4003bfad5fe8fa741434104e3e49a87e1d7fad49e5a8c1d06e57b",
)

const GIT_TAGS_CL = Dict(
    v"4.5.2" => "96b43f314899707810db92149caf518bdb7cf39f7c0ad86e98ad687ffb0d396d",
    v"5.2.3" => "932ea3cd268410010c0830d977a30ef9c14b8c37617d3572a062b5d4595e2b94",
)
const GIT_TAGS_CLR = Dict(
    v"4.5.2" => "6581916a3303a31f76454f12f86e020fb5e5c019f3dbb0780436a8f73792c4d1",
    v"5.2.3" => "0493c414d4db1af8e1eb30a651d9512044644244488ebb13478c2138a7612998",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

function get_hip_cmake(cmake_cxx_prefix::String, version::VersionNumber)
    if version < v"4.5.2"
        cmake_cxx_prefix *= raw"""
        CXXFLAGS="-isystem ${prefix}/rocclr/include/elf -isystem ${prefix}/include/elfutils -isystem ${prefix}/rocclr/include/compiler/lib/include $CXXFLAGS " \
        """
        setup_and_patches = raw"""
        cd ${WORKSPACE}/srcdir/HIP*/
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"
        atomic_patch -p1 --binary "${WORKSPACE}/srcdir/patches/no-init-abort.patch"
        """
        install_license = raw"""
        install_license ${WORKSPACE}/srcdir/HIP*/LICENSE.txt
        """
        cmake_flags = raw"""
        -DHSA_PATH="${prefix}/hsa" \
        """
    else
        setup_and_patches = raw"""
        export HIPAMD_DIR=$(realpath ${WORKSPACE}/srcdir/hipamd-*)
        export HIP_DIR=$(realpath ${WORKSPACE}/srcdir/HIP-*)
        export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr-*)
        export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime-*)

        cd ${ROCclr_DIR}
        atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
        atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-disable-tls.patch

        cd ${WORKSPACE}/srcdir/hipamd*/
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/improve-compilation-disable-tests.patch"
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-init-abort.patch"
        """
        install_license = raw"""
        install_license ${WORKSPACE}/srcdir/hipamd*/LICENSE.txt
        """
        cmake_flags = raw"""
        -DROCCLR_INCLUDE_DIR="${ROCclr_DIR}/include" \
        -DROCCLR_PATH=${ROCclr_DIR} \
        -DHIP_COMMON_DIR=${HIP_DIR} \
        -DHIP_SRC_PATH=${HIPAMD_DIR} \
        -DAMD_OPENCL_PATH=${OPENCL_SRC} \
        """
    end

    setup_and_patches *
    raw"""
    mkdir build && cd build
    """ *
    cmake_cxx_prefix *
    raw"""
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_INSTALL_PREFIX="${prefix}/hip" \
        -DLLVM_DIR="${prefix}/llvm/lib/cmake/llvm" \
        -DClang_DIR="${prefix}/llvm/lib/cmake/clang" \
        -DROCM_PATH=${prefix} \
        -DHIP_PLATFORM=amd \
        -DHIP_RUNTIME=rocclr \
        -DHIP_COMPILER=clang \
        -D__HIP_ENABLE_PCH=OFF \
    """ *
    cmake_flags *
    raw"""
    ..
    """ *
    raw"""
    make -j${nproc}
    make install
    """ *
    install_license
end

const PRODUCTS = [
    LibraryProduct("libamdhip64", :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

function configure_build(version)
    archive = "archive/rocm-$version.tar.gz"

    sources = [
        ArchiveSource(HIP_GIT * archive, HIP_GIT_TAGS[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    if version ≥ v"4.5.2"
        push!(
            sources,
            ArchiveSource(HIPAMD_GIT * archive, HIPAMD_GIT_TAGS[version]),
            ArchiveSource(ROCM_GIT_CL * "archive/rocm-$(version).tar.gz", GIT_TAGS_CL[version]),
            ArchiveSource(ROCM_GIT_CLR * "archive/rocm-$(version).tar.gz", GIT_TAGS_CLR[version]))
    end

    cmake_cxx_prefix = raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    """
    buildscript = get_hip_cmake(cmake_cxx_prefix, version)

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
