const NAME = "MIOpen"

const ROCM_GIT = "https://github.com/ROCmSoftwarePlatform/MIOpen/"
const GIT_TAGS = Dict(
    v"4.2.0" => "547f6d5d38a41786839f01c5bfa46ffe9937b389193a8891f251e276a1a47f11",
)
const ROCM_PLATFORMS = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
const PRODUCTS = [LibraryProduct(["libMIOpen"], :libmiopen, ["miopen/lib"])]

const BUILDSCRIPT = raw"""
cd ${WORKSPACE}/srcdir/rocBLAS*/
mkdir build

export ROCM_PATH=${prefix}
export HIP_PATH=${prefix}/hip

export HIP_PLATFORM=amd
export HIP_RUNTIME=rocclr
export HIP_COMPILER=clang
export HSA_PATH=${prefix}
# export HIP_ROCCLR_HOME=${prefix}/lib
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

CXX=${prefix}/hip/bin/hipcc \
cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=${prefix}/hip/bin/hipcc \
    -DCMAKE_CXX_FLAGS="-fuse-ld=lld" \
    -DROCM_PATH={prefix} \
    -DBUILD_VERBOSE=ON \

make -j${nproc} -C build install

install_license ${WORKSPACE}/srcdir/MIOpen*/LICENSE.txt
"""

function configure_build(version)
    sources = [
        ArchiveSource(
            ROCM_GIT * "archive/rocm-$(version).tar.gz", GIT_TAGS[version]),
    ]
    dependencies = [
        BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version)),
        BuildDependency(PackageSpec(; name="rocm_cmake_jll", version)),
        Dependency("ROCmOpenCLRuntime_jll", version),
        Dependency("rocminfo_jll", version),
        Dependency("HIP_jll", version),
        Dependency("rocBLAS_jll", version),
    ]
    NAME, version, sources, BUILDSCRIPT, ROCM_PLATFORMS, PRODUCTS, dependencies
end
