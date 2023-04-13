using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUTENSOR"
version = v"1.6.1"#.5
version_str = "1.6.1.5"

platforms_and_sources = Dict(
    Platform("x86_64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-x86_64/libcutensor-linux-x86_64-$(version_str)-archive.tar.xz",
                      "793b425c30ffd423c4f3a2e94acaf4fcb6752264aa73b74695a002dd2fe94b1a")],
    Platform("powerpc64le", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-ppc64le/libcutensor-linux-ppc64le-$(version_str)-archive.tar.xz",
                      "e895476ab13c4a28bdf018f23299746968564024783c066a2602bc0f09b86e47")],
    Platform("aarch64", "linux") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/linux-sbsa/libcutensor-linux-sbsa-$(version_str)-archive.tar.xz",
                      "f0644bbdca81b890056a7b92714e787333b06a4bd384e4dfbdc3938fbd132e65")],
    Platform("x86_64", "windows") => [
        ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/redist/libcutensor/windows-x86_64/libcutensor-windows-x86_64-$(version_str)-archive.zip",
                      "36eac790df7b2c7bb4578cb355f1df65d17965ffc9b4f6218d1cdb82f87ab866")],
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

builds = ["10.2", "11"]
for build in builds
    include("build_$(build).jl")
    cuda_version = VersionNumber(build)

    for (platform, sources) in platforms_and_sources
        if platform == Platform("aarch64", "linux") && cuda_version < v"11"
            # ARM binaries are only provided for CUDA 11+
            continue
        end
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
