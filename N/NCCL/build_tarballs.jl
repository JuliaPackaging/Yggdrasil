# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.26.5"

MIN_CUDA_VERSION = v"11.8" # doesnt quite match NCCL actual support

sources = [
    GitSource("https://github.com/NVIDIA/nccl.git", "3000e3c797b4b236221188c07aa09c1f3a0170d4"),
]


script = raw"""
cd $WORKSPACE/srcdir

export TMPDIR=${WORKSPACE}/tmpdir # we need a lot of tmp space
mkdir -p ${TMPDIR}

# Necessary operations to cross compile CUDA from x86_64 to aarch64
if [[ "${target}" == aarch64-linux-* ]]; then

   # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
   
   # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
   rm -rf ${prefix}/cuda/bin
   cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin
   
   rm -rf ${prefix}/cuda/nvvm/bin
   cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin

   export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
fi

export CXXFLAGS='-D__STDC_FORMAT_MACROS'
export CUDARTLIB=cudart # link against dynamic library

export CUDA_HOME=${prefix}/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc/nccl thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

cd nccl
make -j ${nproc} src.build CUDA_HOME=${CUDA_HOME} PREFIX=${prefix}

make install PREFIX=${prefix}

rm -f ${WORKSPACE}/srcdir/nccl/build/lib/libnccl_static.a

install_license ${WORKSPACE}/srcdir/nccl/LICENSE.txt

if [[ "${target}" == aarch64-linux-* ]]; then
   # ensure products directory is clean
   rm -rf ${prefix}/cuda
fi
"""


platforms = CUDA.supported_platforms(min_version = MIN_CUDA_VERSION)
filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)


products = [
    LibraryProduct("libnccl", :libnccl),
]

dependencies = [
    HostBuildDependency("coreutils_jll"), # requires fmt
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    cuda_ver = platform["cuda"]

    platform_sources = BinaryBuilder.AbstractSource[sources...]

    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(cuda_ver, "x86_64"))
    end

    build_tarballs(ARGS, name, version, platform_sources, script, [platform],
                   products, [dependencies; cuda_deps]; 
                   lazy_artifacts=true, julia_compat="1.10", 
                   preferred_gcc_version = v"10",
                   augment_platform_block = CUDA.augment)
end
