using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUTENSOR"
version = v"1.7.0"
version_str = "1.7.0.1"

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-x86_64/libcutensor-linux-x86_64-$(version_str)-archive.tar.xz",
                      "dd3557891371a19e73e7c955efe5383b0bee954aba6a30e4892b0e7acb9deb26")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-ppc64le/libcutensor-linux-ppc64le-$(version_str)-archive.tar.xz",
                      "af4ad5e29dcb636f1bf941ed1fd7fc8053eeec4813fbc0b41581e114438e84c8")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-sbsa/libcutensor-linux-sbsa-$(version_str)-archive.tar.xz",
                      "c31f8e4386539434a5d1643ebfed74572011783b4e21b62be52003e3a9de3720")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/windows-x86_64/libcutensor-windows-x86_64-$(version_str)-archive.zip",
                      "cdbb53bcc1c7b20ee0aa2dee781644a324d2d5e8065944039024fe22d6b822ab")],
)

augment_platform_block = CUDA.augment

products = [
    LibraryProduct(["libcutensor", "cutensor"], :libcutensor),
    LibraryProduct(["libcutensorMg", "cutensorMg"], :libcutensorMg),
]

dependencies = [
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    RuntimeDependency(PackageSpec(name="CompilerSupportLibraries_jll",
                                  uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

builds = ["11", "12"]
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

# bump
