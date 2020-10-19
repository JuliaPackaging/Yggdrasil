include("../../fancy_toys.jl")

version = v"1.2.0"

name = "CUTENSOR_CUDA$(cuda_version.major)$(cuda_version.minor)"

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.0/local_installers/libcutensor-linux-x86_64-1.2.0.tar.gz",
                  "0b33694d391bca537cad0f349b77b31fe45f668abdaee7de9133ca30d3bded6e")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.0/local_installers/libcutensor-linux-ppc64le-1.2.0.tar.gz",
                  "892fa6b3f48bd9f46dcc3001fe702e88605c2b6b65709815aa558e4823539617")
]
sources_windows = [
    FileSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.0/local_installers/libcutensor_1.2.0.exe",
                  "1e1dcffc9a91d88cbe89d039838bf0d0be0e4928751cd03a8274a262ec1ebba3")
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
