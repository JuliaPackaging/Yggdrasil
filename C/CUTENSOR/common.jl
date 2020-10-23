include("../../fancy_toys.jl")

version = v"1.2.1"#.7

name = "CUTENSOR_CUDA$(cuda_version.major)$(cuda_version.minor)"

sources_linux_x64 = [
    ArchiveSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.1/local_installers/libcutensor-linux-x86_64-1.2.1.7.tar.gz",
                  "9e8c61d0fee821363c61c105ab0ec33b7f594dd49a79b18eefd509e33004eae2")
]
sources_linux_ppc64le = [
    ArchiveSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.1/local_installers/libcutensor-linux-ppc64le-1.2.1.7.tar.gz",
                  "195ae404136e2ad202e50dd4bfd15af0835699ec8b8f7d2ff08a807ccb2ded4a")
]
sources_windows = [
    FileSource("https://developer.nvidia.com/compute/cutensor/secure/1.2.1/local_installers/libcutensor_1.2.1.exe",
                  "e548484e2116297a9e35d463c98e26ea37e0645941861e63fe5ffb29436269fb")
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
