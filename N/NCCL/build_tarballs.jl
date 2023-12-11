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
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

cd nccl
make -j src.build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = CUDA.supported_platforms()

products = [
    LibraryProduct("libnccl", :libnccl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                   products, [dependencies; cuda_deps]; lazy_artifacts=true,
                   julia_compat="1.7", CUDA.augment,
                   skip_audit=true, dont_dlopen=true)
end
