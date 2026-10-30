# build_tarballs.jl
# BinaryBuilder.jl recipe for Tigre_jll (libtigre_julia)

using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

# Support platforms and helpers from Yggdrasil
if isfile(joinpath(@__DIR__, "../../platforms/cuda.jl"))
    include("../../platforms/cuda.jl")
else
    include(joinpath(@__DIR__, "platforms/cuda.jl"))
end

name = "Tigre"
version = v"2.7.0"

# Sources: CERN/TIGRE upstream GitSource and bundled Julia shims/overlays
# Note: GitHub automatic tarball archives are rejected by BinaryBuilderBase due to unstable checksums.
# GitSource with a pinned commit hash is the standard, stable source format in Yggdrasil.
sources = [
    GitSource(
        "https://github.com/CERN/TIGRE.git",
        "81b6be2cc12ee630d36cba941e111ba14ba34c7c",
    ),
    DirectorySource("./bundled"),
]

# Bash script executed inside BinaryBuilder sandbox
script = raw"""
cd ${WORKSPACE}/srcdir

# 1. Locate TIGRE source root
if [ -d "TIGRE" ]; then
    TIGRE_DIR="TIGRE"
elif [ -d "Common/CUDA" ]; then
    TIGRE_DIR="."
else
    TIGRE_DIR=$(find . -maxdepth 2 -iname "tigre*" -type d | head -n 1)
fi

if [ -z "${TIGRE_DIR}" ] || [ ! -d "${TIGRE_DIR}/Common/CUDA" ]; then
    echo "ERROR: TIGRE source directory not found! Listing srcdir:"
    ls -la
    exit 1
fi
COMMON_DIR="${TIGRE_DIR}/Common/CUDA"

# 2. Apply overlay files to Common/CUDA
if [ -d "overlay" ]; then
    echo "Applying overlays to ${COMMON_DIR}..."
    cp -fv overlay/TIGRE_common.hpp "${COMMON_DIR}/"
    cp -fv overlay/TIGRE_common.cpp "${COMMON_DIR}/"
fi

# 3. Collect source files
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
    "wrapper/src/tigre_julia_runtime.cpp"
    "wrapper/src/tigre_julia_shim.cpp"
)

# 4. Locate CUDA toolkit and nvcc compiler
if [ -d "${prefix}/cuda" ]; then
    CUDA_HOME="${prefix}/cuda"
elif [ -d "${WORKSPACE}/destdir/cuda" ]; then
    CUDA_HOME="${WORKSPACE}/destdir/cuda"
else
    CUDA_HOME="/usr/local/cuda"
fi

NVCC="nvcc"
if [ -f "${CUDA_HOME}/bin/nvcc" ]; then
    NVCC="${CUDA_HOME}/bin/nvcc"
elif command -v nvcc >/dev/null 2>&1; then
    NVCC="$(command -v nvcc)"
fi
echo "Using nvcc at: ${NVCC}"
${NVCC} --version

# Compute capability / architecture flags
# Selected architectures for SASS generation, plus PTX fallback for future GPUs
ARCH_FLAGS=(
    "-gencode=arch=compute_70,code=sm_70"
    "-gencode=arch=compute_75,code=sm_75"
    "-gencode=arch=compute_80,code=sm_80"
    "-gencode=arch=compute_86,code=sm_86"
    "-gencode=arch=compute_89,code=sm_89"
    "-gencode=arch=compute_90,code=sm_90"
    "-gencode=arch=compute_86,code=compute_86"
)

INCLUDE_FLAGS=(
    "-I${COMMON_DIR}"
    "-Iwrapper/include"
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

# 5. Compile shared library libtigre_julia
echo "Compiling libtigre_julia..."
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
    -o "${libdir}/libtigre_julia.${dlext}"

# 6. Install license files
install_license "${TIGRE_DIR}/LICENSE.txt"
if [ -f "LICENSE" ]; then
    install_license "LICENSE"
fi
"""

# Products: exported shared library
products = [
    LibraryProduct("libtigre_julia", :libtigre_julia),
]

# Base platform: Linux x86_64 glibc
base_platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
]

# Targeted CUDA versions for initial recipe: CUDA 12 series (e.g. 12.4)
cuda_platforms = Platform[]
for p in base_platforms
    plat = deepcopy(p)
    plat["cuda"] = "12.4"
    push!(cuda_platforms, plat)
end

# Non-platform arguments passed to build_tarballs
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

for plat in cuda_platforms
    deps = BinaryBuilder.AbstractDependency[
        CUDA.required_dependencies(plat)...
    ]

    build_tarballs(
        non_platform_ARGS,
        name,
        version,
        sources,
        script,
        [plat],
        products,
        deps;
        julia_compat = "1.10",
        augment_platform_block = CUDA.augment,
        preferred_gcc_version = v"10",
    )
end
