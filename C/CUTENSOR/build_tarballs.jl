using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUTENSOR"
version = v"1.3.0"#.3

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/1.3.0/local_installers/libcutensor-linux-x86_64-1.3.0.3.tar.gz",
                      "80c3124497bd8692fd4e98376589372eee616a55f875a2a28961087322d45d00")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/1.3.0/local_installers/libcutensor-linux-ppc64le-1.3.0.3.tar.gz",
                      "5e60569be31be0377fec94392be3c7b844181dbf9b0731dd87e87d0b9ff38258")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/1.3.0/local_installers/libcutensor-windows-x86_64-1.3.0.3.zip",
                      "599ad469846d9a22d608a768d45c29138c6ba03247593aee56a999306489e840")],
)

products = [
    LibraryProduct(["libcutensor", "cutensor"], :libcutensor, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [
    Dependency(PackageSpec(name="CUDA_loader_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
                           uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3"]
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
