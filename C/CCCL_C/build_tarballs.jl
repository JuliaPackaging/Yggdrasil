# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CCCL_C"

# CCCL's C API (libcccl.c.parallel) is experimental and only stable within a single
# release, so we pin an exact commit and never mix headers and library from different
# ones. This is the commit NVIDIA's cuda-cccl 1.1.1 wheels were built from (tag
# python-1.1.1, on the CCCL 3.5.0 release line), because the Windows artifacts
# repackage the library from those wheels.
version = v"3.5.0"
commit = "793a80bd837eaa758713462a170c896a9028b312"

git_sources = [
    GitSource("https://github.com/NVIDIA/cccl.git", commit),
]

# nvcc cannot cross-compile for Windows (it requires MSVC as host compiler), so on
# Windows we repackage NVIDIA's MSVC-built library from the cuda-cccl wheel. The wheel
# is built from the pinned commit, and its header trees are byte-identical to the git
# checkout (modulo line endings), so the exact-match requirement between headers and
# library holds. The DLL is identical across the per-Python wheels; use any one.
wheel_sources = [
    FileSource("https://files.pythonhosted.org/packages/89/c5/865c61dba948d55d2403f54002c7b8685037458200dc6a728643b3f90b84/cuda_cccl-1.1.1-cp312-cp312-win_amd64.whl",
               "3dc79837d45cd79e54bf7370f9d27f39285be5621a4d2c0252b6b9e83a57ae97";
               filename="cuda_cccl.whl"),
]

build_script = raw"""
cd $WORKSPACE/srcdir/cccl

export TMPDIR=${WORKSPACE}/tmpdir # nvcc needs a lot of tmp space
mkdir -p ${TMPDIR}

# the CMake provided in the build environment is too old; use CMake_jll instead
apk del cmake

# Necessary operations to cross compile CUDA from x86_64 to aarch64
if [[ "${target}" == aarch64-linux-* ]]; then

   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"

   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-linux-x86_64-*-archive)
   NVVM_DIR=(/workspace/srcdir/libnvvm-linux-x86_64-*-archive)

   rm -rf ${prefix}/cuda/bin
   cp -a "${NVCC_DIR[0]}/bin" "${prefix}/cuda/bin"

   # CUDA <= 12.9: nvvm may still be inside cuda_nvcc.
   # CUDA >= 13.0: nvvm is a separate redist.
   if [[ -d "${NVCC_DIR[0]}/nvvm/bin" ]]; then
      rm -rf ${prefix}/cuda/nvvm/bin
      cp -a "${NVCC_DIR[0]}/nvvm/bin" "${prefix}/cuda/nvvm/bin"

      if [[ -d "${NVCC_DIR[0]}/nvvm/lib64" ]]; then
         rm -rf ${prefix}/cuda/nvvm/lib64
         cp -a "${NVCC_DIR[0]}/nvvm/lib64" "${prefix}/cuda/nvvm/lib64"
      fi

   elif [[ -d "${NVVM_DIR[0]}/nvvm/bin" ]]; then
      rm -rf ${prefix}/cuda/nvvm/bin
      cp -a "${NVVM_DIR[0]}/nvvm/bin" "${prefix}/cuda/nvvm/bin"

      if [[ -d "${NVVM_DIR[0]}/nvvm/lib64" ]]; then
         rm -rf ${prefix}/cuda/nvvm/lib64
         cp -a "${NVVM_DIR[0]}/nvvm/lib64" "${prefix}/cuda/nvvm/lib64"
      fi

   else
      echo "ERROR: no host x86_64 nvvm/bin found; cannot cross-compile CUDA device code"
      exit 1
   fi

   export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
fi

export CUDA_HOME=${prefix}/cuda
export PATH=$PATH:$CUDA_HOME/bin

# nvcc's link driver looks in lib64/, but the SDK ships lib/
ln -sf lib ${prefix}/cuda/lib64

# the library contains essentially no SASS (all algorithm kernels are JIT-compiled with
# NVRTC at runtime), so build only for the minimum supported architecture
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
    -DCCCL_ENABLE_C_PARALLEL=ON \
    -DCCCL_C_Parallel_ENABLE_TESTING=OFF \
    -DCCCL_ENABLE_LIBCUDACXX=OFF \
    -DCCCL_ENABLE_CUB=OFF \
    -DCCCL_ENABLE_THRUST=OFF \
    -DCCCL_ENABLE_TESTING=OFF \
    -DCCCL_ENABLE_EXAMPLES=OFF \
    -Dlibcudacxx_ENABLE_INSTALL_RULES=ON \
    -DCUB_ENABLE_INSTALL_RULES=ON \
    -DThrust_ENABLE_INSTALL_RULES=ON
cmake --build build --parallel ${nproc}

# installs the CUB/Thrust/libcudacxx header trees, which the library needs to feed NVRTC
# at runtime; these must exactly match the library
cmake --install build

# the library and the C API headers have no install rules; install manually
install -Dm755 build/lib/libcccl.c.parallel.so ${libdir}/libcccl.c.parallel.so
cp -a c/parallel/include/cccl ${includedir}/cccl

# drop the CMake package files that the header install rules drag in
rm -rf ${prefix}/lib/cmake ${prefix}/lib64/cmake

install_license LICENSE

if [[ "${target}" == aarch64-linux-* ]]; then
   # ensure products directory is clean
   rm -rf ${prefix}/cuda
else
   rm -f ${prefix}/cuda/lib64
fi
"""

windows_script = raw"""
cd $WORKSPACE/srcdir
unzip -d wheel cuda_cccl.whl

# the wheel ships one library per CUDA major
cuda_major=$(echo $bb_full_target | sed -E 's/.*cuda\+([0-9]+).*/\1/')
install -Dm755 wheel/cuda/compute/cu${cuda_major}/cccl/cccl.c.parallel.dll \
    ${libdir}/cccl.c.parallel.dll

# headers from the pinned source: byte-identical to the wheel's, but with the same
# line endings as the artifacts of the other platforms
cd cccl
mkdir -p ${includedir}
cp -a cub/cub thrust/thrust libcudacxx/include/cuda libcudacxx/include/nv ${includedir}/
cp -a c/parallel/include/cccl ${includedir}/cccl

install_license LICENSE
"""

products = [
    # NB: upstream soname is dotted: libcccl.c.parallel.so / cccl.c.parallel.dll.
    # links libcuda.so.1/nvcuda.dll (driver), so cannot be dlopened at audit time.
    # the Windows library is MSVC-built and additionally needs the Visual C++
    # redistributable (MSVCP140.dll etc.) at runtime.
    LibraryProduct(["libcccl.c.parallel", "cccl.c.parallel"], :libcccl_c_parallel; dont_dlopen=true),
    # header trees, so consumers can resolve include paths robustly
    FileProduct("include/cub/version.cuh", :cub_version_header),
    FileProduct("include/thrust/version.h", :thrust_version_header),
    FileProduct("include/cuda/std/version", :libcudacxx_version_header),
    FileProduct("include/cccl/c/reduce.h", :cccl_c_header),
]

dependencies = [
    HostBuildDependency(PackageSpec(name="CMake_jll", version="3.31.9")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

builds = []

# One artifact per CUDA major series. All algorithm kernels are JIT-compiled at runtime
# by NVRTC against the shipped headers, and cudart is statically linked, so the library
# does not depend on the CUDA runtime at all. What it does depend on is the driver (all
# symbols it binds exist in CUDA 12.0 already) and a JIT stack of the same major as its
# nvrtc/nvJitLink sonames, at least as new as the SDK used to build (CUB's tuning
# policies bind PTX ISA requirements at build time that the JIT must satisfy). Artifact
# selection is therefore keyed on CUDA_Compiler_jll -- which provides that JIT stack,
# by default the newest GA toolkit compatible with the driver, or a local toolkit
# whose version satisfies the tag -- with the platform tag naming the oldest
# supported toolkit series.
#
# We build with the oldest SDK that works, to keep the JIT stack requirement low. The
# floor within 12.x is 12.8: the host code uses std::format, requiring GCC 13, which
# nvcc accepts as of CUDA 12.4; and CUB's decoupled-lookahead scan requires PTX ISA 8.6
# (CUDA 12.8). NB: NVIDIA builds the Windows libraries with the newest toolkit of each
# major instead; we still apply our tag, as no additional ISA requirements are bound.
cuda_builds = [
    v"12.8",
    v"13.0",
    # CUDA < 13.4 miscompiles the lookahead scan for sm_120, so CUB disables it for
    # that architecture at library-build time. A 13.4 build re-enables it, requiring a
    # 13.4+ JIT stack (which the tag then expresses). switch over once CUDA 13.4 is GA:
    #v"13.4",
]

for sdk in cuda_builds
    # Linux: build from source
    for platform in CUDA.supported_platforms(; min_version=sdk,
                                               max_version=VersionNumber(sdk.major, sdk.minor, 999))
        should_build_platform(triplet(platform)) || continue

        platform_sources = BinaryBuilder.AbstractSource[git_sources...]
        if arch(platform) == "aarch64"
            components = ["cuda_nvcc"]
            if sdk >= v"13"
                push!(components, "libnvvm")
            end
            x86_platform = deepcopy(platform)
            x86_platform["arch"] = "x86_64"
            append!(platform_sources, get_sources("cuda", components;
                                                  version=CUDA.full_version(sdk),
                                                  platform=x86_platform))
        end

        # static SDK for libcudart_static.a.
        # CUDA_Compiler_jll 0.5+ provides nvrtc/nvJitLink at runtime.
        deps = [dependencies;
                BuildDependency(PackageSpec(name="CUDA_SDK_jll",
                                            version=string(CUDA.full_version(sdk))));
                BuildDependency(PackageSpec(name="CUDA_SDK_static_jll",
                                            version=string(CUDA.full_version(sdk))));
                RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.5")]

        push!(builds, (; platforms=[platform], sources=platform_sources, deps,
                         script=build_script))
    end

    # Windows: repackage NVIDIA's wheel (see above). cudart is statically linked and
    # the driver/JIT libraries are loaded dynamically, so no SDK is needed.
    platform = Platform("x86_64", "windows")
    platform["cuda"] = CUDA.platform(sdk)
    if should_build_platform(triplet(platform))
        deps = [RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.5")]
        push!(builds, (; platforms=[platform],
                         sources=BinaryBuilder.AbstractSource[git_sources; wheel_sources],
                         deps, script=windows_script))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, build.script,
        build.platforms, products, build.deps;
        julia_compat="1.10",
        # selection is keyed on the compiler, not the runtime (see above)
        augment_platform_block=CUDA.compiler_augment,
        lazy_artifacts=true,
        dont_dlopen=true,
        preferred_gcc_version=v"13")
end

# bump
