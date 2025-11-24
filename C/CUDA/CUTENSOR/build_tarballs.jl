using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUTENSOR"
version = v"2.3.1"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/libcutensor.so* ${libdir}
    mv lib/libcutensorMg.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv bin/cutensor.dll ${libdir}
    mv bin/cutensorMg.dll ${libdir}
    mv lib/cutensor.lib ${libdir}
    mv lib/cutensorMg.lib ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.dll
fi"""

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

platforms = [Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "windows")]

builds = []
for cuda_version in [v"12", v"13"], platform in platforms
    augmented_platform = deepcopy(platform)
    if cuda_version == v"12" && arch(platform) == "aarch64"
        augmented_platform["cuda_platform"] = "sbsa"
    end
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    sources = get_sources("cutensor", ["libcutensor"]; version, platform=augmented_platform,
                          variant="cuda$(cuda_version.major)")

    push!(builds, (; platforms=[augmented_platform], sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, dependencies;
                   julia_compat="1.6", augment_platform_block, dont_dlopen=true)
end
