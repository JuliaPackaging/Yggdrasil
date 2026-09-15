# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, libc

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA", "common.jl"))

name = "whisper_cpp"
version = v"1.9.3"

# url = "https://github.com/ggml-org/whisper.cpp"
# description = "Port of OpenAI's Whisper speech-to-text model in C/C++"
#
# Layout follows L/llama_cpp (same ggml core): libwhisper links the split ggml
# libraries (libggml, libggml-base, libggml-cpu) which are shipped alongside it.
# v1.9.x also ships libparakeet (NVIDIA Parakeet ASR models).
#
# Accelerators:
# - all platforms: CPU. On x86_64/i686 we assume AVX/AVX2/FMA/F16C (as llama_cpp does).
# - aarch64-apple-darwin: Metal (embedded shader library, compiled at runtime)
# - x86_64-linux-gnu and aarch64-linux-gnu: CUDA, as separately tagged artifacts
#   selected through the "cuda" platform tag (see platforms/cuda.jl). The CPU
#   artifacts carry no "cuda" tag, so they remain the fallback on hosts without
#   CUDA_Runtime_jll.

sources = [
    GitSource("https://github.com/ggml-org/whisper.cpp.git",
              "371b5a7561823ab2bb32142d2751e35e7534727b"),  # v1.9.3
]

script = raw"""
cd $WORKSPACE/srcdir/whisper.cpp*

# Avoid forcing -march on riscv64 (BinaryBuilder disallows explicit -march)
sed -i -e 's/list(APPEND ARCH_FLAGS "-march=${MARCH_STR}" -mabi=lp64d)/list(APPEND ARCH_FLAGS -mabi=lp64d)/' ggml/src/ggml-cpu/CMakeLists.txt
sed -i -e 's/list(APPEND ARCH_FLAGS -march=rv64gc_v -mabi=lp64d)/list(APPEND ARCH_FLAGS -mabi=lp64d)/' ggml/src/ggml-cpu/CMakeLists.txt
# Guard the Windows thread power throttling API, which mingw's headers lack
sed -i -e 's/#if _WIN32_WINNT >= 0x0602/#if _WIN32_WINNT >= 0x0602 \&\& defined(THREAD_POWER_THROTTLING_CURRENT_VERSION)/' ggml/src/ggml-cpu/ggml-cpu.c
# gguf.cpp uses errno without including <cerrno> (fails on macOS)
grep -q '<cerrno>' ggml/src/gguf.cpp || sed -i '1i#include <cerrno>' ggml/src/gguf.cpp

EXTRA_CMAKE_ARGS=()
EXE_LDFLAGS=""

if [[ "${target}" == *-linux-* ]]; then
    EXE_LDFLAGS="-lrt"
fi

if [[ "${target}" == x86_64-* || "${target}" == i686-* ]]; then
    EXTRA_CMAKE_ARGS+=(-DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_FMA=ON -DGGML_F16C=ON)
fi

# Metal: Apple Silicon only. The Metal shader library is embedded as source and
# compiled at runtime, so no Metal toolchain is needed at build time.
if [[ "${target}" == aarch64-apple-darwin* ]]; then
    EXTRA_CMAKE_ARGS+=(-DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON)
elif [[ "${target}" == x86_64-apple-darwin* ]]; then
    EXTRA_CMAKE_ARGS+=(-DGGML_METAL=OFF)
fi

# CUDA (only for platforms tagged cuda=<version>)
cuda_version=${bb_full_target##*-cuda+}
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    # nvcc writes to /tmp, which is a small tmpfs in our sandbox
    export TMPDIR=${WORKSPACE}/tmpdir
    mkdir -p ${TMPDIR}

    export CUDA_HOME=${prefix}/cuda
    export PATH=${PATH}:${CUDA_HOME}/bin

    if [[ "${target}" == aarch64-linux-* ]]; then
        # nvcc is not a cross compiler: run the x86_64 host nvcc (from the
        # cuda_nvcc redist added to the sources for aarch64 builds) against the
        # aarch64 CUDA SDK that CUDA_SDK_jll put in ${prefix}/cuda.
        export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"

        NVCC_DIR=(/workspace/srcdir/cuda_nvcc-linux-x86_64-*-archive)
        rm -rf ${CUDA_HOME}/bin
        cp -a "${NVCC_DIR[0]}/bin" ${CUDA_HOME}/bin

        # CUDA <= 12.x ships nvvm inside cuda_nvcc; CUDA >= 13 ships it separately
        if [[ -d "${NVCC_DIR[0]}/nvvm/bin" ]]; then
            NVVM_DIR="${NVCC_DIR[0]}"
        else
            NVVM_DIR_ARR=(/workspace/srcdir/libnvvm-linux-x86_64-*-archive)
            NVVM_DIR="${NVVM_DIR_ARR[0]}"
        fi
        rm -rf ${CUDA_HOME}/nvvm/bin ${CUDA_HOME}/nvvm/lib64
        cp -a "${NVVM_DIR}/nvvm/bin" ${CUDA_HOME}/nvvm/bin
        [[ -d "${NVVM_DIR}/nvvm/lib64" ]] && cp -a "${NVVM_DIR}/nvvm/lib64" ${CUDA_HOME}/nvvm/lib64
    fi

    export CUDACXX=${CUDA_HOME}/bin/nvcc
    # reduces fatbin size; linking fails past 2GB when targeting many archs
    export NVCC_PREPEND_FLAGS+=' -Xfatbin=-compress-all'

    # CUDA_SDK_jll keeps libraries in cuda/lib, while nvcc (per its nvcc.profile)
    # and FindCUDAToolkit look in lib64 first; and it ships the shared cudart only
    # (libcudart.so, libcudadevrt.a, no libcudart_static.a). So point nvcc at the
    # right directory and link the shared runtime, which is what we want anyway:
    # CUDA_Runtime_jll provides libcudart/libcublas at run time.
    [[ -e ${CUDA_HOME}/lib64 ]] || ln -s lib ${CUDA_HOME}/lib64
    export CUDAFLAGS="-cudart=shared"
    # ggml-cuda links the driver API; libggml-cuda ends up needing libcuda.so.1 (the
    # real soname, provided by the driver at run time) but the SDK stubs directory
    # only has libcuda.so, so give ld the soname it will look for.
    [[ -e ${CUDA_HOME}/lib/stubs/libcuda.so.1 ]] || ln -s libcuda.so ${CUDA_HOME}/lib/stubs/libcuda.so.1

    # The executables link against libggml-cuda, whose own DT_NEEDED entries
    # (libcudart, libcublas, libcuda) must be resolvable by ld at link time.
    # The SDK libraries from CUDA 12.8 on (and the aarch64 13.x ones) reference
    # glibc symbols newer than our sysroot (log2f@GLIBC_2.27,
    # __cxa_thread_atexit_impl@GLIBC_2.18) in libcublasLt; that is fine on any
    # host that can run those CUDA versions, so do not fail the link on it.
    EXE_LDFLAGS+=" -Wl,-rpath-link,${CUDA_HOME}/lib -Wl,-rpath-link,${CUDA_HOME}/lib/stubs -Wl,--allow-shlib-undefined"

    EXTRA_CMAKE_ARGS+=(
        -DGGML_CUDA=ON
        -DCMAKE_CUDA_COMPILER=${CUDACXX}
        -DCMAKE_CUDA_HOST_COMPILER=${CXX}
        -DCMAKE_CUDA_FLAGS="-cudart=shared"
        -DCMAKE_CUDA_RUNTIME_LIBRARY=Shared
        -DCUDAToolkit_ROOT=${CUDA_HOME}
        # NCCL is optional and not available here
        -DGGML_CUDA_NCCL=OFF
    )
    # With GGML_NATIVE=OFF and CMAKE_CUDA_ARCHITECTURES unset, ggml picks a
    # portable architecture list appropriate for the toolkit version
    # (PTX for older archs, SASS for the common ones, Blackwell on >= 12.8).
fi

cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SKIP_RPATH=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_NATIVE=OFF \
    -DWHISPER_BUILD_IS_DEV=OFF \
    -DWHISPER_BUILD_TESTS=OFF \
    -DWHISPER_BUILD_EXAMPLES=ON \
    -DWHISPER_BUILD_SERVER=OFF \
    -DWHISPER_SDL2=OFF \
    -DWHISPER_CURL=OFF \
    -DCMAKE_EXE_LINKER_FLAGS="${EXE_LDFLAGS}" \
    "${EXTRA_CMAKE_ARGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE

if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    # keep the CUDA SDK out of the products
    rm -rf ${prefix}/cuda
fi
"""

# std::filesystem is used by the examples
sources, script = require_macos_sdk("10.15", sources, script)

# ---------------------------------------------------------------------------
# CPU builds
# ---------------------------------------------------------------------------

platforms = supported_platforms()
# Never built for these in the previous recipe; llama_cpp has the same exclusions
# (missing NEON intrinsics on armv6/7, no __POWER9_VECTOR__ on ppc64le).
filter!(p -> !(arch(p) in ("armv6l", "armv7l", "powerpc64le")), platforms)
# aarch64-linux-musl: HWCAP_ASIMDDP undeclared in ggml-cpu.c (same as llama_cpp)
filter!(p -> !(Sys.islinux(p) && arch(p) == "aarch64" && libc(p) == "musl"), platforms)
platforms = expand_cxxstring_abis(platforms)

cpu_products = [
    LibraryProduct(["libwhisper", "whisper"], :libwhisper),
    LibraryProduct(["libparakeet", "parakeet"], :libparakeet),
    LibraryProduct(["libggml", "ggml"], :libggml),
    LibraryProduct(["libggml-base", "ggml-base"], :libggml_base),
    LibraryProduct(["libggml-cpu", "ggml-cpu"], :libggml_cpu),
    ExecutableProduct("whisper-cli", :whisper_cli),
    ExecutableProduct("whisper-bench", :whisper_bench),
    ExecutableProduct("whisper-quantize", :whisper_quantize),
]

dependencies = [
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll", uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# ---------------------------------------------------------------------------
# CUDA builds
# ---------------------------------------------------------------------------
#
# An artifact built against CUDA X.Y is selected for any host with CUDA X.Z, Z >= Y,
# and when several match the highest version wins (select_platform sorts by triplet).
# So builds are only needed at feature boundaries rather than for every minor:
#   12.2  JetPack 6.0 (Jetson Orin) and the oldest 12.x we support
#   12.6  JetPack 6.1/6.2
#   12.8  Blackwell (sm_120) support in ggml
#   13.0  CUDA 13 (JetPack 7); no jetson/sbsa split any more
cuda_versions = ("12.2", "12.6", "12.8", "13.0")

cuda_platforms = CUDA.supported_platforms(; min_version = v"12.2")
filter!(p -> arch(p) in ("x86_64", "aarch64") && p["cuda"] in cuda_versions, cuda_platforms)
cuda_platforms = expand_cxxstring_abis(cuda_platforms)

cuda_products = [
    cpu_products...,
    LibraryProduct(["libggml-cuda", "ggml-cuda"], :libggml_cuda),
]

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

# Platform selection is handled per build below, so `build_tarballs` must not
# filter on the positional platform argument itself. Select by exact triplet:
# `platforms_match` treats a missing "cuda" tag as a wildcard, so a CPU triplet
# would also pick up every CUDA build (and vice versa), and a CI job for one
# platform would build them all serially.
const requested_triplets = let args = filter(a -> !startswith(a, "--"), ARGS)
    isempty(args) ? nothing : Set(String.(split(args[1], ",")))
end
wanted(p) = requested_triplets === nothing || triplet(p) in requested_triplets

non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)
# `--register` should only be passed to the last `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

builds = []

for platform in platforms
    wanted(platform) || continue
    push!(builds, (; platform, sources, products = cpu_products,
                     dependencies, dont_dlopen = false))
end

for platform in cuda_platforms
    wanted(platform) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"
        # host (x86_64) nvcc, plus libnvvm which is a separate redist from CUDA 13 on
        cuda_ver = VersionNumber(platform["cuda"])
        components = ["cuda_nvcc"]
        cuda_ver >= v"13" && push!(components, "libnvvm")
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources,
                get_sources("cuda", components; platform = x86_platform,
                            version = CUDA.full_version(cuda_ver)))
    end

    push!(builds, (; platform, sources = platform_sources, products = cuda_products,
                     dependencies = [dependencies; CUDA.required_dependencies(platform)],
                     dont_dlopen = true))   # libcuda is not available in the sandbox
end

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script, [build.platform],
                   build.products, build.dependencies;
                   julia_compat = "1.10",
                   preferred_gcc_version = v"10",
                   augment_platform_block = CUDA.augment,
                   dont_dlopen = build.dont_dlopen)
end
