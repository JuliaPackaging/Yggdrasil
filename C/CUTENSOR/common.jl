include("../../fancy_toys.jl")

version = v"1.2.2"#.5

name = "CUTENSOR_CUDA$(cuda_version.major)$(cuda_version.minor)"

sources_linux_x64 = [
    ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/1.2.2/local_installers/libcutensor-linux-x86_64-1.2.2.5.tar.gz",
                  "954ee22b80d6b82fd4decd42b7faead86af7c3817653b458620a66174e5b89b6")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/1.2.2/local_installers/libcutensor-linux-ppc64le-1.2.2.5.tar.gz",
                  "d914a721b8a6bbfbf4f2bdea3bb51775e5df39abc383d415b3b06bbde2a47e6e")
]
sources_windows = [
    FileSource("https://developer.download.nvidia.com/compute/cutensor/1.2.2/local_installers/libcutensor_1.2.2.exe",
               "88d3e2c662e601214ef5caa26ca2db0492eab6ec3bf9dc9a746bb1a7b8c3aab2")
]

products = [
    LibraryProduct(["libcutensor", "cutensor"], :libcutensor),
]

dependencies = [
    Dependency(PackageSpec(name="CUDA_jll", version=cuda_version)),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if @isdefined(sources_linux_x64) && should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_x64, script,
                   [Platform("x86_64", "linux")], products, dependencies)
end

if @isdefined(sources_linux_ppc64le) && should_build_platform("powerpc64le-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux_ppc64le, script,
                   [Platform("powerpc64le", "linux")], products, dependencies)
end

if @isdefined(sources_windows) && should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Platform("x86_64", "windows")], products, dependencies)
end
