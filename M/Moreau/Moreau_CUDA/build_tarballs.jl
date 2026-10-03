# Copyright, the Moreau authors
# SPDX-License-Identifier: Apache-2.0

using BinaryBuilder, Pkg

# This recipe is laid out for M/Moreau/Moreau_CUDA in Yggdrasil.
const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "C", "CUDA", "common.jl"))

name = "Moreau_CUDA"
version = v"0.4.1"
base_sources = [GitSource("https://github.com/moreau-project/moreau.git",
    "799c9fdc0d3cb7675e723a3fb9eb413015a64f93")]
script = raw"""
cd ${WORKSPACE}/srcdir/moreau
install_license LICENSE NOTICE
export TMPDIR=${WORKSPACE}/tmpdir
mkdir -p ${TMPDIR}
export CUDA_HOME=${prefix}/cuda
# The ARM SDK contains ARM executables. Run matching x86-64 compiler tools on
# the builder, while retaining the ARM headers and libraries for the target.
if [[ ${target} == aarch64-linux-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    nvcc_source=(${WORKSPACE}/srcdir/cuda_nvcc-linux-x86_64-*-archive)
    nvvm_source=(${WORKSPACE}/srcdir/libnvvm-linux-x86_64-*-archive)
    rm -rf ${CUDA_HOME}/bin
    cp -a "${nvcc_source[0]}/bin" ${CUDA_HOME}/bin
    if [[ -d ${nvcc_source[0]}/nvvm/bin ]]; then
        nvvm_source=("${nvcc_source[0]}")
    fi
    rm -rf ${CUDA_HOME}/nvvm/bin ${CUDA_HOME}/nvvm/lib64
    cp -a "${nvvm_source[0]}/nvvm/bin" ${CUDA_HOME}/nvvm/bin
    if [[ -d ${nvvm_source[0]}/nvvm/lib64 ]]; then
        cp -a "${nvvm_source[0]}/nvvm/lib64" ${CUDA_HOME}/nvvm/lib64
    fi
    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
fi
export PATH=${CUDA_HOME}/bin:${PATH}
export CUDACXX=${CUDA_HOME}/bin/nvcc
ln -s lib ${CUDA_HOME}/lib64
${host_bindir}/cmake -S packages/moreau-cuda -B build \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCUDAToolkit_ROOT=${CUDA_HOME} \
    -DCUDSS_ROOT=${prefix} \
    -DCMAKE_CUDA_ARCHITECTURES="${CUDAARCHS}" \
    -DMOREAU_BUILD_C_SHARED=ON \
    -DMOREAU_BUILD_PYTHON=OFF \
    -DMOREAU_BUILD_TESTS=OFF \
    -DMOREAU_BUILD_EXAMPLES=OFF \
    -DMOREAU_VERSION=0.4.1
${host_bindir}/cmake --build build --target moreau_cuda_shared -j${nproc}
mkdir -p ${libdir} ${includedir}
cp -a build/libmoreau_cuda.so* ${libdir}/
cp packages/moreau-c/include/moreau.h ${includedir}/
# Do not package the x86-64 compiler tools substituted into an ARM SDK.
if [[ ${target} == aarch64-linux-* ]]; then
    rm -rf ${CUDA_HOME}
fi
"""
products = [LibraryProduct("libmoreau_cuda", :libmoreau_cuda)]
# Retain 0.7.1: Moreau reverted cuDSS 0.8 after performance and determinism regressions.
dependencies = [
    HostBuildDependency(PackageSpec(name="CMake_jll", version=v"3.31.9+0")),
    Dependency("CUDSS_jll", v"0.7.1"; compat="=0.7.1"),
    Dependency("CompilerSupportLibraries_jll"),
]
platforms = CUDA.supported_platforms()
# Moreau's CUDA 12 release baseline is toolkit 12.2.
filter!(p -> VersionNumber(p["cuda"]) >= v"12.2", platforms)
# cuDSS 0.7.1 only provides binaries for the CUDA 12 and 13 runtime ABIs.
filter!(p -> VersionNumber(p["cuda"]) < v"14", platforms)

filter!(p -> should_build_platform(triplet(p)), platforms)
# Each variant has different SDK dependencies; do not let build_tarballs expand it
# back to the full command-line platform list.
build_args = filter(arg -> startswith(arg, "--"), ARGS)
non_register_args = filter(arg -> arg != "--register", build_args)

for (i, platform) in enumerate(platforms)
    sources = BinaryBuilder.AbstractSource[base_sources...]
    if arch(platform) == "aarch64"
        cuda_version = VersionNumber(platform["cuda"])
        components = ["cuda_nvcc"]
        cuda_version >= v"13" && push!(components, "libnvvm")
        host_platform = deepcopy(platform)
        host_platform["arch"] = "x86_64"
        append!(sources, get_sources("cuda", components;
            version=CUDA.full_version(cuda_version), platform=host_platform))
    end
    gpu_archs = CUDA.cuda_gpu_archs(platform)
    # Orin needs sm_87 in addition to the generic architecture list.
    arch(platform) == "aarch64" && push!(gpu_archs, "87")
    archs = join(gpu_archs, ";")
    build_tarballs(i == lastindex(platforms) ? build_args : non_register_args,
        name, version, sources,
        "export CUDAARCHS=\"$archs\"\n" * script, [platform], products,
        [dependencies; CUDA.required_dependencies(platform; static_sdk=true)];
        julia_compat="1.12", preferred_gcc_version=v"11",
        augment_platform_block=CUDA.augment, lazy_artifacts=true, dont_dlopen=true)
end
