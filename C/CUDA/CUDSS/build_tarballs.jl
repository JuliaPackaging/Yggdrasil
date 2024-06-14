using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDSS"
version = v"0.2.0"
full_version = "0.2.0.12"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then

    cd libcudss-*
    install_license LICENSE
    mv lib/libcudss*.so* ${libdir}
    mv include/* ${prefix}/include

elif [[ ${target} == x86_64-w64-mingw32 ]]; then

    cd libcudss-*
    install_license LICENSE
    mv lib/cudss.lib ${prefix}/lib
    mv bin/cudss*64_*.dll ${libdir}
    mv include/* ${prefix}/include

    # fixup
    chmod +x ${libdir}/*.dll
fi
"""

augment_platform_block = CUDA.augment

products = [
    LibraryProduct(["libcudss", "cudss64_$(version.major)"], :libcudss),
]

dependencies = [RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))]

platforms = [Platform("x86_64", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

builds = []
for cuda_version in [v"12"], platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    sources = get_sources("cudss", ["libcudss"]; version=version, platform,
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
