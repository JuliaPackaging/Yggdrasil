# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.30.7"

git_sources = [
    GitSource("https://github.com/NVIDIA/nccl.git", "73cf112295c33aee2b895f329f592f2a9b4b0f97"),
    DirectorySource("./bundled/")
]


build_script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done

export TMPDIR=${WORKSPACE}/tmpdir # we need a lot of tmp space
mkdir -p ${TMPDIR}

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

export CXXFLAGS='-D__STDC_FORMAT_MACROS -D_GNU_SOURCE -Wno-unused-parameter -Wno-type-limits -Wno-error -Wno-missing-field-initializers -Wno-implicit-fallthrough'
export NVCCFLAGS="$NVCCFLAGS -Wno-unused-parameter"
export CUDARTLIB=cudart # link against dynamic library

export CUDA_HOME=${prefix}/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc
export CUDA_LIB=${CUDA_HOME}/lib

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

products = [
    LibraryProduct("libnccl", :libnccl),
]

dependencies = [
    HostBuildDependency("coreutils_jll"), # requires fmt
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

builds = []


for platform in CUDA.supported_platforms(; min_version=v"12", max_version=v"13.0.999")
    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[git_sources...]
    if arch(platform) == "aarch64"
        push!(platform_sources, CUDA.cuda_nvcc_redist_source(platform["cuda"], "x86_64"))
        cuda_ver = VersionNumber(platform["cuda"])
        if v"13.0" <= cuda_ver < v"13.1"
            lib_nvvm_sources = get_sources("cuda", ["libnvvm"]; version=v"13.0", platform=Platform("x86_64", "linux"; cuda="13.0"))
            push!(platform_sources, lib_nvvm_sources...)
        elseif cuda_ver > v"13.0"
            error("Add libnvvm redist source to build NCCL for CUDA $cuda_ver on aarch64")
        end
    end

    push!(
        builds,
        (; platforms=[platform], sources=platform_sources, script=build_script, req_deps=true)
    )
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    if build.req_deps
        deps = [dependencies; CUDA.required_dependencies(build.platforms[1])]
    else
        deps = []
    end

    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, build.script,
        build.platforms, products, deps;
        julia_compat="1.10", augment_platform_block=CUDA.augment,
        preferred_gcc_version=v"10")
end
