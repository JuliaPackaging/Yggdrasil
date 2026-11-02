# build_tarballs.jl
# BinaryBuilder.jl recipe for Tigre_jll (libtigre)

using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

# Support platforms and helpers from Yggdrasil
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Compatibility shim for older local BinaryBuilderBase where `tag` kwarg is not yet supported
let BB = parentmodule(GitSource)
    if !hasmethod(GitSource, Tuple{String, String}, (:tag,))
        Core.eval(BB, :(GitSource(url::String, hash::String; tag::String = "", unpack_target::String = "") = GitSource(url, hash, unpack_target)))
    end
end

name = "Tigre"
version = v"3.1.3"

# Sources: CERN/TIGRE upstream GitSource and bundled Julia shims/overlays
# Note: GitHub automatic tarball archives are rejected by BinaryBuilderBase due to unstable checksums.
# GitSource with a pinned commit hash and release tag is the standard, stable source format in Yggdrasil.
sources = [
    GitSource(
        "https://github.com/CERN/TIGRE.git",
        "9aad4fe623e8e0dbc5fed32958973e1173185ea0";
        tag = "v$(version)",
    ),
    DirectorySource("./bundled"),
]

# Bash script executed inside BinaryBuilder sandbox
script = raw"""
cd ${WORKSPACE}/srcdir/TIGRE

# 1. Normalize line endings to LF (upstream CERN/TIGRE has mixed CRLF/LF line endings)
find Common/CUDA -type f -exec dos2unix {} +

# 2. Apply patches from bundled/patches
if [ -d "${WORKSPACE}/srcdir/patches" ]; then
    for f in ${WORKSPACE}/srcdir/patches/*.patch; do
        echo "Applying patch ${f}..."
        atomic_patch -p1 ${f}
    done
fi

# 3. Apply overlay files to Common/CUDA
if [ -d "${WORKSPACE}/srcdir/overlay" ]; then
    echo "Applying overlays to Common/CUDA..."
    cp -fv ${WORKSPACE}/srcdir/overlay/TIGRE_common.hpp Common/CUDA/
    cp -fv ${WORKSPACE}/srcdir/overlay/TIGRE_common.cpp Common/CUDA/
fi

COMMON_DIR="Common/CUDA"

# 4. Collect source files
UPSTREAM_SOURCES=(
    "${COMMON_DIR}/projection.cpp"
    "${COMMON_DIR}/TIGRE_common.cpp"
    "${COMMON_DIR}/GpuIds.cpp"
    "${COMMON_DIR}/gpuUtils.cu"
    "${COMMON_DIR}/Siddon_projection.cu"
    "${COMMON_DIR}/Siddon_projection_parallel.cu"
    "${COMMON_DIR}/ray_interpolated_projection.cu"
    "${COMMON_DIR}/ray_interpolated_projection_parallel.cu"
    "${COMMON_DIR}/voxel_backprojection.cu"
    "${COMMON_DIR}/voxel_backprojection2.cu"
    "${COMMON_DIR}/voxel_backprojection_parallel.cu"
    "${COMMON_DIR}/GD_TV.cu"
    "${COMMON_DIR}/GD_AwTV.cu"
    "${COMMON_DIR}/tv_proximal.cu"
    "${COMMON_DIR}/PICCS.cu"
)

WRAPPER_SOURCES=(
    "${WORKSPACE}/srcdir/wrapper/src/tigre_julia_runtime.cpp"
    "${WORKSPACE}/srcdir/wrapper/src/tigre_julia_shim.cpp"
)

# 5. Locate CUDA toolkit and nvcc compiler
CUDA_HOME="${prefix}/cuda"
NVCC="${CUDA_HOME}/bin/nvcc"

# Determine CUDA major version
cuda_major=12
if [[ ${bb_full_target} == *-cuda+* ]]; then
    cuda_ver=${bb_full_target##*-cuda+}
    cuda_major=${cuda_ver%%.*}
elif ${NVCC} --version &>/dev/null; then
    cuda_ver=$(${NVCC} --version | sed -n 's/.*release \([0-9]*\)\..*/\1/p')
    if [ -n "${cuda_ver}" ]; then
        cuda_major="${cuda_ver}"
    fi
fi

# Compute capability / architecture flags
# Selected architectures for SASS generation, plus PTX fallback for future GPUs
ARCH_FLAGS=()

# CUDA < 13 supports Volta (sm_70); CUDA 13+ dropped sm_70 support
if [ "${cuda_major}" -lt 13 ]; then
    ARCH_FLAGS+=("-gencode=arch=compute_70,code=sm_70")
fi

ARCH_FLAGS+=(
    "-gencode=arch=compute_75,code=sm_75"
    "-gencode=arch=compute_80,code=sm_80"
    "-gencode=arch=compute_86,code=sm_86"
    "-gencode=arch=compute_89,code=sm_89"
    "-gencode=arch=compute_90,code=sm_90"
    "-gencode=arch=compute_86,code=compute_86"
)

INCLUDE_FLAGS=(
    "-I${COMMON_DIR}"
    "-I${WORKSPACE}/srcdir/wrapper/include"
    "-I${CUDA_HOME}/include"
    "-I${prefix}/include"
)

LIB_FLAGS=(
    "-L${CUDA_HOME}/lib64"
    "-L${CUDA_HOME}/lib"
    "-L${libdir}"
    "-lcudart"
)

mkdir -p "${libdir}"

# 6. Compile shared library libtigre
echo "Compiling libtigre..."
${NVCC} --shared -O3 --std=c++14 \
    --cudart shared \
    --expt-relaxed-constexpr \
    -Xcompiler=-fPIC \
    -Xlinker=--allow-multiple-definition \
    -DIS_FOR_JULIA_TIGRE \
    "${INCLUDE_FLAGS[@]}" \
    "${ARCH_FLAGS[@]}" \
    "${UPSTREAM_SOURCES[@]}" \
    "${WRAPPER_SOURCES[@]}" \
    "${LIB_FLAGS[@]}" \
    -o "${libdir}/libtigre.${dlext}"

# 7. Install license files
install_license LICENSE.txt
install_license "${WORKSPACE}/srcdir/LICENSE"
"""

# Products: exported shared library
products = [
    LibraryProduct("libtigre", :libtigre),
]

# Platforms: Start from CUDA-supported platforms and filter as needed
# TIGRE directly invokes the nvcc compiler without an aarch64 cross-nvcc toolchain
platforms = CUDA.supported_platforms(; min_version = v"12.0")
filter!(p -> arch(p) == "x86_64", platforms)

dependencies = [
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll")),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    deps = BinaryBuilder.AbstractDependency[
        dependencies;
        CUDA.required_dependencies(platform)...
    ]

    build_tarballs(
        ARGS,
        name,
        version,
        sources,
        script,
        [platform],
        products,
        deps;
        lazy_artifacts = true,
        julia_compat = "1.10",
        augment_platform_block = CUDA.augment,
        dont_dlopen = true,
        preferred_gcc_version = v"10",
    )
end
