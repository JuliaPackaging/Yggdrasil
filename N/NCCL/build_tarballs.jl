# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os, tags

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.28.3"

git_sources = [
    GitSource("https://github.com/NVIDIA/nccl.git", "f1308997d0420148b1be1c24d63f19d902ae589b"),
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
   NVCC_DIR=(/workspace/srcdir/cuda_nvcc-*-archive)
   rm -rf ${prefix}/cuda/bin
   cp -r ${NVCC_DIR}/bin ${prefix}/cuda/bin

   rm -rf ${prefix}/cuda/nvvm/bin
   cp -r ${NVCC_DIR}/nvvm/bin ${prefix}/cuda/nvvm/bin

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

redist_script = raw"""

cd ${WORKSPACE}/srcdir/nccl*

install_license LICENSE.txt

for file in lib/libnccl*.${dlext}*; do
    install -Dvm 755 "${file}" -t "${libdir}"
done

find include -type f -print0 | while IFS= read -r -d '' file; do
    relpath="${file#include/}"
    install -Dvm644 "$file" "${includedir}/${relpath}"
done
"""

products = [
    LibraryProduct("libnccl", :libnccl),
]

dependencies = [
    HostBuildDependency("coreutils_jll"), # requires fmt
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

builds = []

# redist for sources that are available
for cuda_version in [v"13.0"]
    platforms = [
        Platform("x86_64", "linux"),
        Platform("aarch64", "linux")
    ]
    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(cuda_version)
        should_build_platform(triplet(augmented_platform)) || continue

        if cuda_version == v"12.9"
            if arch(platform) == "aarch64"
                hash = "c51b970bb26a0d3afd676048923fc404ed1d1131441558a7d346940e93d6ab54"
            elseif arch(platform) == "x86_64"
                hash = "98f7abd2f505ba49f032052f3f36b14e28798a6e16ca783fe293e351e9376546"
            end
        else
            if arch(platform) == "aarch64"
                hash = "2b5961c4c4bcbc16148d8431c7b65525d00f386105ab1b9fa82051b7c05f6fd0"
            elseif arch(platform) == "x86_64"
                hash = "3117db0efe13e1336dbe32e8b98eab943ad5baa69518189918d4aca9e3ce3270"
            end
        end

        sources = [
            ArchiveSource("https://developer.download.nvidia.com/compute/redist/nccl/v$(version)/nccl_$(version)-1+cuda$(cuda_version.major).$(cuda_version.minor)_$(arch(platform)).txz", hash)
        ]

        push!(
            builds,
            (; platforms=[augmented_platform], sources, script=redist_script, req_deps=false)
        )
    end
end

for platform in CUDA.supported_platforms(; min_version=v"12", max_version=v"12.9.999")
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
