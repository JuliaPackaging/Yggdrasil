# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.19.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/NVIDIA/nccl.git", "88d44d777f6970bdbf6610badcbd7e25a05380f0"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

export TMPDIR=${WORKSPACE}/tmpdir # we need a lot of tmp space
export CUDA_HOME=${WORKSPACE}/destdir/cuda
export CUDA_LIB=${CUDA_HOME}/lib
export CXXFLAGS='-D__STDC_FORMAT_MACROS'
export CUDARTLIB=cudart # link against dynamic library

mkdir -p ${TMPDIR}

cd nccl

atomic_patch -p1 ../patches/busid.patch

make -j pkg.txz.build
tar -xJf build/pkg/txz/*.txz -C ${WORKSPACE}/destdir --strip-components=1
rm ${WORKSPACE}/destdir/LICENSE.txt
rm ${WORKSPACE}/destdir/lib/libnccl_static.a  # remove static library: saves 230 MB

install_license ${WORKSPACE}/srcdir/nccl/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = CUDA.supported_platforms()
filter!(p -> arch(p) == "x86_64", platforms)

products = [
    LibraryProduct("libnccl", :libnccl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("coreutils_jll"), # requires fmt
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps]; 
                   lazy_artifacts=true,
                   julia_compat="1.6", 
                   augment_platform_block = CUDA.augment)
end
