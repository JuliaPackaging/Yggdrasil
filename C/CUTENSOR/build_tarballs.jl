using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../../fancy_toys.jl")

name = "CUTENSOR"
version = v"1.4.0"#.6

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-x86_64/libcutensor-linux-x86_64-1.4.0.6-archive.tar.xz",
                      "467ba189195fcc4b868334fc16a0ae1e51574139605975cc8004cedebf595964")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-ppc64le/libcutensor-linux-ppc64le-1.4.0.6-archive.tar.xz",
                      "5da44ff2562ab7b9286122653e54f28d2222c8aab4bb02e9bdd4cf7e4b7809be")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-sbsa/libcutensor-linux-sbsa-1.4.0.6-archive.tar.xz",
                      "6b06d63a5bc49c1660be8c307795f8a901c93dcde7b064455a6c81333c7327f4")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/windows-x86_64/libcutensor-windows-x86_64-1.4.0.6-archive.zip",
                      "4f01a8aac2c25177e928c63381a80e3342f214ec86ad66965dcbfe81fc5c901d")],
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

cuda_versions = [v"10.2", v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5", v"11.6"]
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
