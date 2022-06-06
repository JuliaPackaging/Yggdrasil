using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDA_Runtime"
version = v"0.1"

cuda_versions = [v"10.0", v"10.2",
                 v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5", v"11.6"]

augment_platform_block = """
    using Base.BinaryPlatforms

    $(CUDA.augment)

    augment_cuda_toolkit!(platform) = augment_cuda_toolkit!(platform, $cuda_versions)

    function augment_platform!(platform::Platform)
        augment_cuda_toolkit!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for platform in platforms
        augmented_platform = deepcopy(platform)
        augmented_platform[CUDA.platform_name] = CUDA.platform(cuda_version)

        should_build_platform(triplet(augmented_platform)) || continue
        push!(builds, (;
            dependencies, script, products,
            platforms=[augmented_platform],
        ))
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, [], build.script,
                   build.platforms, build.products, build.dependencies;
                   julia_compat="1.6", lazy_artifacts=true,
                   augment_platform_block)
end
