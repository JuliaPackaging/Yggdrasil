# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# CCCL's C parallel library, in its second-generation, HostJIT-based form
# (libcccl.c.parallel.v2). Where v1 JIT-compiled CUB with NVRTC and linked user
# operators as LTO-IR (which only NVVM can produce), v2 compiles both the host dispatch
# code and the CUB kernels with an embedded Clang/LLD (libnvcc) and the upstream NVPTX
# back-end, and links user operators supplied as LLVM IR with LLVM's own linker, so they
# inline into the CUB kernels. That makes it usable with operators compiled by Julia's
# NVPTX back-end.
#
# v1 and v2 cannot be built in one CMake tree and ship different headers under the same
# names, so only v2 is built. It only supports x86_64 hosts, and there are no
# MSVC-built v2 libraries to repackage for Windows (NVIDIA's wheels ship v1).
name = "CCCL_C"

# The C API is experimental and only stable within a single release: pin an exact
# commit. This is tag python-1.3.0 (cuda-cccl 1.3.0, CCCL 3.6 release line), whose
# c/parallel.v2 tree is identical to v3.6.0-rc2's.
version = v"3.6.0"
commit = "62b7ac2454d3baf893f51037d3e5b19c32c4b724"

# Upstream builds libnvcc against LLVM 22.1.1, fetched and built at configure time.
# We link the static libraries of LLVM_full_jll instead (see the bundled patch).
llvm_version = v"22.1.8"

sources = [
    GitSource("https://github.com/NVIDIA/cccl.git", commit),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/cccl
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/libnvcc-prebuilt-llvm.patch

export TMPDIR=${WORKSPACE}/tmpdir # nvcc needs a lot of tmp space
mkdir -p ${TMPDIR}

# the CMake provided in the build environment is too old; use CMake_jll instead
apk del cmake

export CUDA_HOME=${prefix}/cuda
export PATH=$PATH:$CUDA_HOME/bin

# nvcc's link driver looks in lib64/, but the SDK ships lib/
ln -sf lib ${prefix}/cuda/lib64

# libnvcc statically links nvFatbin and the PTX compiler, which the SDK JLLs lack
for lib in nvfatbin nvptxcompiler; do
    cp -a /workspace/srcdir/*-archive/lib/lib${lib}_static.a ${prefix}/cuda/lib/
done
cp -a /workspace/srcdir/libnvfatbin-*-archive/include/* ${prefix}/cuda/include/

# the library itself contains no kernels of interest (everything is JIT-compiled at
# run time), so build only for the minimum supported architecture
cuda_arch=$(sed -n 's/^set(minimum_cccl_arch \([0-9]*\).*/\1/p' cmake/CCCLCheckCudaArchitectures.cmake)
[[ -n "${cuda_arch}" ]] || { echo "ERROR: could not determine minimum_cccl_arch"; exit 1; }

cmake -B build -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_COMPILER=${CUDA_HOME}/bin/nvcc \
    -DCMAKE_CUDA_HOST_COMPILER=${CXX} \
    -DCUDAToolkit_ROOT=${CUDA_HOME} \
    -DCMAKE_CUDA_ARCHITECTURES=${cuda_arch} \
    -DLIBNVCC_LLVM_PREFIX=${prefix} \
    -DCCCL_C_PARALLEL_V2_LIBRARY_OUTPUT_DIRECTORY=$(pwd)/build/lib \
    -DCCCL_ENABLE_C_PARALLEL_V2=ON \
    -DCCCL_C_Parallel_V2_ENABLE_TESTING=OFF \
    -DCCCL_ENABLE_LIBCUDACXX=OFF \
    -DCCCL_ENABLE_CUB=OFF \
    -DCCCL_ENABLE_THRUST=OFF \
    -DCCCL_ENABLE_TESTING=OFF \
    -DCCCL_ENABLE_EXAMPLES=OFF \
    -Dlibcudacxx_ENABLE_INSTALL_RULES=ON \
    -DCUB_ENABLE_INSTALL_RULES=ON \
    -DThrust_ENABLE_INSTALL_RULES=ON
cmake --build build --parallel ${nproc}

# installs the CUB/Thrust/libcudacxx header trees, which the JIT compiles against at
# run time (these must exactly match the library), as well as the headers that the
# embedded Clang needs: HostJIT's minimal CUDA runtime wrapper and stubs, and a subset
# of Clang's CUDA and freestanding C headers. The latter two use the wheel's layout
# (cuda/cccl/headers/...), which here would land in the CUDA SDK, so move them.
cmake --install build
mkdir -p ${prefix}/share/cccl
mv ${prefix}/cuda/cccl/headers/hostjit ${prefix}/share/cccl/hostjit
# (the Clang headers are symlinks into the LLVM_full_jll build dependency)
cp -rL ${prefix}/cuda/cccl/headers/clang ${prefix}/share/cccl/clang
rm -rf ${prefix}/cuda/cccl

# the libraries and the C API headers have no install rules
install -Dm755 build/lib/libcccl.c.parallel.v2.so ${libdir}/libcccl.c.parallel.v2.so
install -Dm755 build/lib/libnvcc.so ${libdir}/libnvcc.so
cp -a c/parallel.v2/include/cccl ${includedir}/cccl

# drop the CMake package files that the header install rules drag in
rm -rf ${prefix}/lib/cmake ${prefix}/lib64/cmake

install_license LICENSE

rm -f ${prefix}/cuda/lib64
"""

products = [
    # links libcuda.so.1 (driver) and libnvJitLink, so cannot be dlopened at audit time
    LibraryProduct("libcccl.c.parallel.v2", :libcccl_c_parallel_v2; dont_dlopen=true),
    # embedded Clang/LLD with LLVM, Clang and LLD statically linked and hidden
    LibraryProduct("libnvcc", :libnvcc; dont_dlopen=true),
    FileProduct("include/cub/version.cuh", :cub_version_header),
    FileProduct("include/thrust/version.h", :thrust_version_header),
    FileProduct("include/cuda/std/version", :libcudacxx_version_header),
    FileProduct("include/cccl/c/reduce.h", :cccl_c_header),
    FileProduct("share/cccl/hostjit/cuda_minimal/__clang_cuda_runtime_wrapper.h",
                :hostjit_runtime_wrapper_header),
    FileProduct("share/cccl/clang/__clang_cuda_intrinsics.h", :clang_cuda_header),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="CMake_jll", version="3.31.9")),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    # LLVM_full_jll's static LLVMSupport references zlib and zstd
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

builds = []

# One artifact per CUDA major series: libnvcc dynamically links
# nvJitLink (provided at run time by CUDA_Compiler_jll), whose soname is per-major.
cuda_builds = [
    v"12.8",
    v"13.0",
]

for sdk in cuda_builds
    for platform in CUDA.supported_platforms(; min_version=sdk,
                                               max_version=VersionNumber(sdk.major, sdk.minor, 999))
        # HostJIT compiles and links the host code for x86_64 only
        (Sys.islinux(platform) && arch(platform) == "x86_64") || continue
        should_build_platform(triplet(platform)) || continue

        platform_sources = BinaryBuilder.AbstractSource[sources...]
        # the PTX compiler is part of cuda_nvcc before CUDA 13
        append!(platform_sources,
                get_sources("cuda", sdk >= v"13" ? ["libnvfatbin", "libnvptxcompiler"] :
                                                   ["libnvfatbin", "cuda_nvcc"];
                            version=CUDA.full_version(sdk), platform))

        deps = [dependencies;
                BuildDependency(PackageSpec(name="CUDA_SDK_jll",
                                            version=string(CUDA.full_version(sdk))));
                BuildDependency(PackageSpec(name="CUDA_SDK_static_jll",
                                            version=string(CUDA.full_version(sdk))));
                RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.5, 0.6")]

        push!(builds, (; platforms=[platform], sources=platform_sources, deps))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, script,
        build.platforms, products, build.deps;
        julia_compat="1.10",
        augment_platform_block=CUDA.compiler_augment,
        lazy_artifacts=true,
        dont_dlopen=true,
        preferred_gcc_version=v"13")
end
