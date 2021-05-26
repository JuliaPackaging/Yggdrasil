using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "NCCL"
version = v"2.9.9"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir/nccl*
find .

install_license LICENSE.txt

mv lib/libnccl*.so* ${libdir}
mv include/* ${prefix}/include
"""

products = [
    LibraryProduct("libnccl", :libnccl, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [Dependency(PackageSpec(name="CUDA_loader_jll"))]

cuda_versions = [v"10.2", v"11.0", v"11.3"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
    end
end
