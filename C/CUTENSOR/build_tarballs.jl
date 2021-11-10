using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUTENSOR"
version = v"1.3.3"#.2

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-x86_64/libcutensor-linux-x86_64-1.3.3.2-archive.tar.xz",
                      "2e9517f31305872a7e496b6aa8ea329acda6b947b0c1eb1250790eaa2d4e2ecc")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-ppc64le/libcutensor-linux-ppc64le-1.3.3.2-archive.tar.xz",
                      "79f294c4a7933e5acee5f150145c526d6cd4df16eefb63f2d65df1dbc683cd68")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-sbsa/libcutensor-linux-sbsa-1.3.3.2-archive.tar.xz",
                      "0b62d5305abfdfca4776290f16a1796c78c1fa83b203680c012f37d44706fcdb")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/windows-x86_64/libcutensor-windows-x86_64-1.3.3.2-archive.zip",
                      "3abeacbe7085af7026ca1399a77c681c219c10a1448a062964e97aaac2b05851")],
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

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5"]
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
