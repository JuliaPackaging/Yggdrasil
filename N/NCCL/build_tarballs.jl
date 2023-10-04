using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "NCCL"
version = v"2.18.5"
build = 1

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir/nccl*
find .

install_license LICENSE.txt

mv lib/libnccl*.so* ${libdir}
mv include/* ${prefix}/include
"""

augment_platform_block = CUDA.augment

products = [
    LibraryProduct("libnccl", :libnccl),
]

dependencies = [RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))]

# TODO: how does compatibility work here exactly? do we support 11.1-11.7?
#       are we correctly selecting artifacts in that case?
builds = ["11.0", "12.0", "12.2"]
for build in builds
    include("build_$(build).jl")
    cuda_version = VersionNumber(build)

    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform);
                                      cuda=CUDA.platform(cuda_version))
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true,
                       julia_compat="1.6", augment_platform_block,
                       skip_audit=true, dont_dlopen=true)
    end
end
