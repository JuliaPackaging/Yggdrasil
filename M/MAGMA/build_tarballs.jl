# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "MAGMA"
version = v"2.9.0"

# Note: Hopper should still build with CUDA v11.8
# on x86_64, but aarch64 requires CUDA v12.0
MIN_CUDA_VERSION = v"12"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://icl.utk.edu/projectsfiles/magma/downloads/magma-$(version).tar.gz",
                  "ff77fd3726b3dfec3bfb55790b06480aa5cc384396c2db35c56fdae4a82c641c"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

export TMPDIR=${WORKSPACE}/tmpdir # we need a lot of tmp space
mkdir -p ${TMPDIR}

PTROPT=""

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

   # Workaround failed execution of sizeptr in cross-compile builds
   PTROPT="PTRSIZE=8"
fi

export CUDADIR=${prefix}/cuda
export PATH=${PATH}:${CUDADIR}/bin
export CUDACXX=${CUDADIR}/bin/nvcc

# This flag reduces the size of the compiled binaries; if
# they become over 2GB (e.g. due to targeting too many
# compute_XX), linking fails.
# See: https://github.com/NixOS/nixpkgs/pull/220402
export NVCC_PREPEND_FLAGS+=' -Xfatbin=-compress-all'

cd magma*
cp ../make.inc .

# Patch to _64_ suffixes
atomic_patch -p1 ../0001-mangle-to-ILP64.patch

make ${PTROPT} -j${nproc} sparse-shared
make ${PTROPT} install prefix=${prefix}

install_license COPYRIGHT

# ensure products directory is clean
rm -rf ${CUDADIR}
"""

platforms = CUDA.supported_platforms(min_version = MIN_CUDA_VERSION)
filter!(p -> arch(p) == "x86_64" || arch(p) == "aarch64", platforms)
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libmagma", :libmagma; dont_dlopen=true),
    LibraryProduct("libmagma_sparse", :libmagma_sparse; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll", compat="5.1.1"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

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
                   preferred_gcc_version=v"8",
                   julia_compat="1.8",
                   augment_platform_block=CUDA.augment,
                   skip_audit=true, dont_dlopen=true)
end
