using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuQuantum"
version_str = "25.09.0"
version = VersionNumber(version_str)

# Bash recipe for building across all platforms
script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir/cuquantum-*
install_license LICENSE

mv lib/*.so* ${libdir}
mv include/* ${prefix}/include
"""

augment_platform_block = CUDA.augment

dependencies = [
    RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    RuntimeDependency(PackageSpec(name="CUTENSOR_jll"), compat="2.3.1")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcustatevec", :libcustatevec),
    LibraryProduct("libcutensornet", :libcutensornet),
    LibraryProduct("libcudensitymat", :libcudensitymat),
]

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux")]

builds = []
for cuda_version in [v"12", v"13"], platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    if cuda_version <= v"12"
        augmented_platform["cuda_platform"] = "sbsa"
    end
    should_build_platform(triplet(augmented_platform)) || continue

    sources = get_sources("cuquantum", ["cuquantum"]; version=version_str, platform=augmented_platform,
        variant="cuda$(cuda_version.major)")

    push!(builds, (; platforms=[augmented_platform], sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
        name, version, build.sources, script,
        build.platforms, products, dependencies;
        julia_compat="1.6", augment_platform_block, dont_dlopen=true)
end
