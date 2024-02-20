const NAME = "rocPRIM"

const ROCM_GIT = "https://github.com/ROCmSoftwarePlatform/rocPRIM/"
const GIT_TAGS = Dict(
    v"4.2.0" => "3932cd3a532eea0d227186febc56747dd95841732734d9c751c656de9dd770c8",
    v"4.5.2" => "0dc673847e67db672f2e239f299206fe16c324005ddd2e92c7cb7725bb6f4fa6",
    v"5.2.3" => "502f49cf3190f4ac20d0a6b19eb2d0786bb3c5661329940378081f1678aa8e82",
)

const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
const PRODUCTS = [FileProduct(["rocprim/"], :rocprim)]

const ROCM_TARGETS = Dict(
    v"4.2.0" => ["gfx803", "gfx900:xnack-", "gfx906:xnack-", "gfx908:xnack-"],
    v"4.5.2" => ["gfx803", "gfx900:xnack-", "gfx906:xnack-", "gfx908:xnack-", "gfx90a:xnack-", "gfx90a:xnack+", "gfx1030"],
    v"5.2.3" => ["gfx803", "gfx900:xnack-", "gfx906:xnack-", "gfx908:xnack-", "gfx90a:xnack-", "gfx90a:xnack+", "gfx1030"],
)

function get_rocm_targets(version::VersionNumber)
    targets = join(ROCM_TARGETS[version], ";")
    """
    amdgpu_targets=\"$targets\"
    """
end

function configure_build(version)
    buildscript = raw"""
    cd ${WORKSPACE}/srcdir/rocPRIM*/
    mkdir build

    export ROCM_PATH=${prefix}
    export HIP_PATH=${prefix}/hip

    export HIP_PLATFORM=amd
    export HIP_RUNTIME=rocclr
    export HIP_COMPILER=clang
    export HSA_PATH=${prefix}
    export HIP_CLANG_PATH=${prefix}/llvm/bin

    # Other HIPCC env variables.
    export HIPCC_VERBOSE=1
    export HIP_LIB_PATH=${prefix}/hip/lib
    export DEVICE_LIB_PATH=${prefix}/amdgcn/bitcode
    export HIP_CLANG_HCC_COMPAT_MODE=1

    # BB compile HIPCC flags:
    BB_COMPILE_BASE_DIR=/opt/${target}/${target}
    BB_COMPILE_CPP_DIR=${BB_COMPILE_BASE_DIR}/include/c++/*
    OMP_DIR=/opt/${target}/lib/gcc/${target}/*/include
    BB_COMPILE_FLAGS=" -isystem ${OMP_DIR} -isystem ${BB_COMPILE_CPP_DIR} -isystem ${BB_COMPILE_CPP_DIR}/${target} --sysroot=${BB_COMPILE_BASE_DIR}/sys-root"

    # BB link HIPCC flags:
    BB_LINK_GCC_DIR=/opt/${target}/lib/gcc/${target}/*
    BB_LINK_FLAGS=" --sysroot=${BB_COMPILE_BASE_DIR}/sys-root -B ${BB_LINK_GCC_DIR} -L ${BB_LINK_GCC_DIR}  -L ${BB_COMPILE_BASE_DIR}/lib64 -L ${prefix}/lib"

    # Set compile & link flags for hipcc.
    export HIPCC_COMPILE_FLAGS_APPEND=$BB_COMPILE_FLAGS
    export HIPCC_LINK_FLAGS_APPEND=$BB_LINK_FLAGS

    export PATH="${prefix}/hip/bin:${prefix}/llvm/bin:${PATH}"
    export LD_LIBRARY_PATH="${prefix}/lib:${prefix}/llvm/lib:${LD_LIBRARY_PATH}"

    # NOTE
    # Looking at hcc-cmd, it is clear that it is omitting 'hip/include' directory.
    # Therefore we symlink to other directory that it looks at.
    mkdir ${prefix}/lib/include
    ln -s ${prefix}/hip/include/* ${prefix}/lib/include
    """ *
    get_rocm_targets(version) *
    raw"""
    CXX=${prefix}/hip/bin/hipcc \
    cmake -S . -B build \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_PREFIX_PATH=${prefix} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_COMPILER=${prefix}/hip/bin/hipcc \
        -DCMAKE_CXX_FLAGS="-fuse-ld=lld" \
        -DROCM_PATH=${prefix} \
        -DAMDGPU_TARGETS=${amdgpu_targets} \
        -DBUILD_VERBOSE=ON

    make -j${nproc} -C build install

    install_license ${WORKSPACE}/srcdir/rocPRIM*/LICENSE.txt
    """

    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("ROCmCompilerSupport_jll"; compat=string(version)),
        Dependency("ROCmOpenCLRuntime_jll"; compat=string(version)),
        Dependency("ROCmDeviceLibs_jll"; compat=string(version)),
        Dependency("rocminfo_jll"; compat=string(version)),
        Dependency("hsa_rocr_jll"; compat=string(version)),
        Dependency("HIP_jll"; compat=string(version)),
    ]
    NAME, version, sources, buildscript, ROCM_PLATFORMS, PRODUCTS, dependencies
end
