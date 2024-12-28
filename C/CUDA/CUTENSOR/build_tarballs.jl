using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUTENSOR"
version = v"2.0.1"
full_version = "2.0.1.2"

scripts = Dict()
scripts[v"11"] = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/11/libcutensor.so* ${libdir}
    mv lib/11/libcutensorMg.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/11/cutensor.dll ${libdir}
    mv lib/11/cutensorMg.dll ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.dll
fi"""
scripts[v"12"] = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/12/libcutensor.so* ${libdir}
    mv lib/12/libcutensorMg.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd libcutensor*
    find .

    install_license LICENSE

    mv lib/12/cutensor.dll ${libdir}
    mv lib/12/cutensorMg.dll ${libdir}
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
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

builds = []
for cuda_version in [v"11", v"12"], platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    sources = get_sources("cutensor", ["libcutensor"]; version, platform)
    script = scripts[cuda_version]

    push!(builds, (; platforms=[augmented_platform], sources, script))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, products, dependencies;
                   julia_compat="1.6", augment_platform_block, dont_dlopen=true)
end
