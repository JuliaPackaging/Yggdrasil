# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "TropicalGemmC"
version = v"0.1.0"

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ArrogantGao/TropicalGemm_Cuda.git", "3e592f5ccdb1690844b0988f37701271ecda04fa")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd TropicalGemm_Cuda/

export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin

make -j${nproc}
install_license /usr/share/licenses/MIT
"""


augment_platform_block = CUDA.augment

versions_to_build = [
    v"12.1",
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["TropicalGemmC"], :libtropicalgemm),
]

platforms = [
    Platform("x86_64", "linux"),
]

for cuda_version in versions_to_build, platform in platforms

    cuda_platform = (os(platform) == "linux") && (arch(platform) in ["x86_64"])
    if !isnothing(cuda_version) && !cuda_platform
        continue
    end
    
    if cuda_platform
        augmented_platform = Platform(arch(platform), os(platform);
            cxxstring_abi = cxxstring_abi(platform),
            cuda=isnothing(cuda_version) ? "none" : CUDA.platform(cuda_version)
        )
    else
        augmented_platform = deepcopy(platform)
    end
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = AbstractDependency[
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); platforms=filter(!Sys.isbsd, [augmented_platform])),
    ]

    if !isnothing(cuda_version)
        push!(dependencies, BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))))
        push!(dependencies, RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")))
    end

    build_tarballs(ARGS, name, version, sources,  script, [augmented_platform], products, dependencies;
                    preferred_gcc_version=v"8",
                    julia_compat="1.6",
                    augment_platform_block)
end
