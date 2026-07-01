# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.28.9"

git_sources = [
    GitSource("https://github.com/NVIDIA/nccl.git", "dbc86fd06e8b0c4517b95d8958a09ccacf9520c9"),
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

   # Add /usr/lib/csl-musl-x86_64 to LD_LIBRARY_PATH to be able to use host nvcc
   export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"

   # Make sure we use host CUDA executable by copying from the x86_64 CUDA redist
   NVCC_DIRS=(/workspace/srcdir/cuda_nvcc-*-archive)
   NVCC_DIR="${NVCC_DIRS[0]}"

   if [[ ! -d "${NVCC_DIR}" ]]; then
      echo "ERROR: could not find cuda_nvcc archive directory"
      find /workspace/srcdir -maxdepth 2 -type d | sort
      exit 1
   fi

   rm -rf "${prefix}/cuda/bin"
   mkdir -p "${prefix}/cuda"
   cp -a "${NVCC_DIR}/bin" "${prefix}/cuda/bin"

   # CUDA 12.x and earlier often had nvvm/bin inside cuda_nvcc.
   # CUDA 13.x may provide nvvm pieces through the separate libnvvm redist.
   rm -rf "${prefix}/cuda/nvvm"

   if [[ -d "${NVCC_DIR}/nvvm" ]]; then
      cp -a "${NVCC_DIR}/nvvm" "${prefix}/cuda/nvvm"
   else
      LIBNVVM_DIRS=(/workspace/srcdir/libnvvm-*-archive)
      LIBNVVM_DIR="${LIBNVVM_DIRS[0]}"

      if [[ -d "${LIBNVVM_DIR}/nvvm" ]]; then
         cp -a "${LIBNVVM_DIR}/nvvm" "${prefix}/cuda/nvvm"
      elif [[ -d "${LIBNVVM_DIR}/lib64" ]]; then
         # Some layouts may only provide libnvvm.so under lib64.
         # Preserve CUDA-style location expected by tools that look under cuda/nvvm.
         mkdir -p "${prefix}/cuda/nvvm/lib64"
         cp -a "${LIBNVVM_DIR}/lib64/"* "${prefix}/cuda/nvvm/lib64/"
      else
         echo "ERROR: could not find nvvm in cuda_nvcc or libnvvm archives"
         echo "NVCC_DIR=${NVCC_DIR}"
         echo "LIBNVVM_DIR=${LIBNVVM_DIR:-unset}"
         find /workspace/srcdir -maxdepth 4 -type d | sort
         exit 1
      fi
   fi

   export NVCC_PREPEND_FLAGS="-ccbin='${CXX}'"
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
