using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUTENSOR"
version = v"1.6.1"#.5

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-x86_64/libcutensor-linux-x86_64-1.6.1.5-archive.tar.xz",
                      "793b425c30ffd423c4f3a2e94acaf4fcb6752264aa73b74695a002dd2fe94b1a")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-ppc64le/libcutensor-linux-ppc64le-1.6.1.5-archive.tar.xz",
                      "e895476ab13c4a28bdf018f23299746968564024783c066a2602bc0f09b86e47")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-sbsa/libcutensor-linux-sbsa-1.6.1.5-archive.tar.xz",
                      "f0644bbdca81b890056a7b92714e787333b06a4bd384e4dfbdc3938fbd132e65")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/windows-x86_64/libcutensor-windows-x86_64-1.6.1.5-archive.zip",
                      "36eac790df7b2c7bb4578cb355f1df65d17965ffc9b4f6218d1cdb82f87ab866")],
)

products = [
    LibraryProduct(["libcutensor", "cutensor"], :libcutensor, dont_dlopen = true),
    LibraryProduct(["libcutensorMg", "cutensorMg"], :libcutensorMg, dont_dlopen = true),
]

# XXX: CUDA_loader_jll's CUDA tag should match the library's CUDA version compatibility.
#      lacking that, we can't currently dlopen the library

dependencies = [
    Dependency(PackageSpec(name="CUDA_loader_jll")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
                           uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5", v"11.6", v"11.7", v"11.8"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for (platform, sources) in platforms_and_sources
        if platform == Platform("aarch64", "linux") && cuda_version < v"11"
            # ARM binaries are only provided for CUDA 11+
            continue
        end
        augmented_platform = Platform(arch(platform), os(platform); cuda=cuda_tag)
        should_build_platform(triplet(augmented_platform)) || continue
        build_tarballs(ARGS, name, version, sources, script, [augmented_platform],
                       products, dependencies; lazy_artifacts=true)
    end
end
