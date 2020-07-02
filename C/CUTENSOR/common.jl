include("../../fancy_toys.jl")

version = v"1.1.0"

name = "CUTENSOR_CUDA$(cuda_version.major)$(cuda_version.minor)"

sources_linux = [
    ArchiveSource("https://developer.download.nvidia.com/compute/cutensor/secure/1.1.0/local_installers/libcutensor-linux-x86_64-1.1.0.tar.gz",
                  "621aa5689a6c80dc9e196b628916a1f6993a5593866eda4f1b1668374f91a8c2")
]

products = [
    LibraryProduct(["libcutensor"], :libcutensor),
]

dependencies = [Dependency(PackageSpec(name="CUDA_jll", version=cuda_version))]

non_reg_ARGS = filter(arg -> arg != "--register", ARGS)

if @isdefined(sources_linux) && should_build_platform("x86_64-linux-gnu")
    build_tarballs(non_reg_ARGS, name, version, sources_linux, script,
                   [Linux(:x86_64)], products, dependencies)
end

if @isdefined(sources_windows) && should_build_platform("x86_64-w64-mingw32")
    build_tarballs(ARGS, name, version, sources_windows, script,
                   [Windows(:x86_64)], products, dependencies)
end

if @isdefined(sources_macos) && should_build_platform("x86_64-apple-darwin14")
    build_tarballs(ARGS, name, version, sources_macos, script,
                   [MacOS(:x86_64)], products, dependencies)
end
