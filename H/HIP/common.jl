const NAME = "HIP"

const HIPAMD_GIT = "https://github.com/ROCm-Developer-Tools/hipamd.git"
const HIP_GIT = "https://github.com/ROCm-Developer-Tools/HIP.git"

# Needed, since ROCclr is no longer can be built as standalone project.
# So we build it here as well as in ROCmOpenCLRuntime.
const ROCM_GIT_CL = "https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime.git"
const ROCM_GIT_CLR = "https://github.com/ROCm-Developer-Tools/ROCclr.git"

const HIPAMD_GIT_TAGS = Dict(
    v"4.5.2" => "f9dccde41b30375483e20954fcde118eff756959",
    v"5.2.3" => "02187ecfc8a1a6ed2bbca29000a83dec5a61cb7f",
    v"5.4.4" => "474e8620099a463ad2ced821ae7400609b29bf7f",
)
const HIP_GIT_TAGS = Dict(
    v"4.2.0" => "37cb3a34938af39303b73aceb2d7803f5c7ca7ca",
    v"4.5.2" => "3413a164f458bcde4d550f294a5ad628fe2f568b",
    v"5.2.3" => "206b6de40698e20b2310c6dd22241ac9cad574ae",
    v"5.4.4" => "fea9cf73ba64592cdbc6c946d03b2ad2f14b77db",
)

const GIT_TAGS_CL = Dict(
    v"4.2.0" => "549af90fdd3914b1d2a7304a78500a610c457891",
    v"4.5.2" => "bf77cab712343a85cc19abc13afcbfc5af4ceca5",
    v"5.2.3" => "40df4420ea9d0adc7a6e315a50305037c477b05d",
    v"5.4.4" => "00e0533578a588da2c0834c58d550e9379d17e49",
)
const GIT_TAGS_CLR = Dict(
    v"4.2.0" => "f343e8ffe98fbb6824400f5dbbff169e725c1165",
    v"4.5.2" => "307b17e49546864bcc257f476b1a88b6941e3bb8",
    v"5.2.3" => "442ede037c871420f3c810cb4228f5ebc2a133bb",
    v"5.4.4" => "ccd065214094837dd59a45aa5111d860aff38ecf",
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
        cmake_flags = ""
    else
        setup_and_patches = raw"""
        export HIPAMD_DIR=$(realpath ${WORKSPACE}/srcdir/hipamd*)
        export HIP_DIR=$(realpath ${WORKSPACE}/srcdir/HIP*)
        export ROCclr_DIR=$(realpath ${WORKSPACE}/srcdir/ROCclr*)
        export OPENCL_SRC=$(realpath ${WORKSPACE}/srcdir/ROCm-OpenCL-Runtime*)

        # Needed for /bin/hipconfig.pl
        export HIP_CLANG_PATH="${prefix}/llvm/bin"

        cd ${ROCclr_DIR}
        atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
        atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-disable-tls.patch

        cd ${WORKSPACE}/srcdir/hipamd*/
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/improve-compilation-disable-tests.patch"
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/no-init-abort.patch"
        atomic_patch -p1 "${WORKSPACE}/srcdir/patches/register-tracer-callback-no-const.patch"
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
        if version ≥ v"5.2.3"
            cmake_flags *= raw"""
            -DFILE_REORG_BACKWARD_COMPATIBILITY=OFF \
            """
        end
        if version >= v"5.4.4"
            setup_and_patches *= raw"""
            pip3 install CppHeaderParser
            """
        end
    end

    setup_and_patches *
    raw"""
    mkdir build && cd build
    """ *
    cmake_cxx_prefix *
    raw"""
    cmake \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_SKIP_BUILD_RPATH=TRUE \
        -DCMAKE_INSTALL_PREFIX="${prefix}/hip" \
        -DLLVM_DIR="${prefix}/llvm/lib/cmake/llvm" \
        -DClang_DIR="${prefix}/llvm/lib/cmake/clang" \
        -DHSA_PATH="${prefix}/hsa" \
        -DROCM_PATH=${prefix} \
        -DHIP_PLATFORM=amd \
        -DHIP_RUNTIME=rocclr \
        -DHIP_COMPILER=clang \
        -DHIPCC_VERBOSE=7 \
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
    sources = [
        GitSource(HIP_GIT, HIP_GIT_TAGS[version]),
        DirectorySource("./bundled"),
        DirectorySource("../scripts"),
    ]
    if version ≥ v"4.5.2"
        push!(
            sources,
            GitSource(HIPAMD_GIT, HIPAMD_GIT_TAGS[version]),
            GitSource(ROCM_GIT_CL, GIT_TAGS_CL[version]),
            GitSource(ROCM_GIT_CLR, GIT_TAGS_CLR[version]))
    end

    cmake_cxx_prefix = raw"""
    CC=${WORKSPACE}/srcdir/rocm-clang CXX=${WORKSPACE}/srcdir/rocm-clang++ \
    """
    buildscript = get_hip_cmake(cmake_cxx_prefix, version)

    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("hsakmt_roct_jll"; compat=string(version)),
        Dependency("hsa_rocr_jll"; compat=string(version)),
        Dependency("rocminfo_jll"; compat=string(version)),
        Dependency("ROCmDeviceLibs_jll"; compat=string(version)),
        Dependency("ROCmCompilerSupport_jll"; compat=string(version)),
        Dependency("ROCmOpenCLRuntime_jll"; compat=string(version)),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
