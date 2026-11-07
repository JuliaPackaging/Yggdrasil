using BinaryBuilder, Pkg

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# The headers of the CUDA runtime (e.g. `cuda_fp16.h`, `cuda_bf16.h`, `cuda_fp8.h`), for
# compiling code that includes them with NVRTC at run time, as the headers are not part of
# CUDA_Compiler_jll. Artifacts are selected like those of CUDA_Compiler_jll, so the headers
# match the NVRTC in use.
name = "CUDA_Runtime_Headers"
version = v"0.1.0"

const toolkit_versions = [CUDA.cuda_full_versions; CUDA.cuda_prerelease_versions]
const header_versions = filter(v -> v >= v"11.4" || Base.thisminor(v) == v"10.2", toolkit_versions)

# CUDA 10.2 is repackaged from CUDA_SDK_jll (no redistributables exist for it)
include("build_10.2.jl")

script = raw"""
install_license cuda_cudart-*-archive/LICENSE

mkdir -p ${includedir}
cp -r cuda_cudart-*-archive/include/* ${includedir}
"""

products = [
    FileProduct("include/cuda_runtime.h", :cuda_runtime_h),
    FileProduct("include/cuda_fp16.h", :cuda_fp16_h),
    FileProduct("include/cuda_bf16.h", :cuda_bf16_h),
]

dependencies = [
    # for the platform augmentation
    RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.6"),
]

# as for CUDA_Compiler_jll
function get_platforms(version::VersionNumber)
    platforms = if version >= v"13"
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"),
         Platform("x86_64", "windows")]
    else
        [Platform("x86_64", "linux"),
         Platform("aarch64", "linux"; cuda_platform="jetson"),
         Platform("aarch64", "linux"; cuda_platform="sbsa"),
         Platform("x86_64", "windows")]
    end

    filter!(platforms) do platform
        arch(platform) == "aarch64" || return true

        minor = Base.thisminor(version)
        if minor == v"10.2" && platform["cuda_platform"] != "jetson"
            return false
        end
        if v"11" <= minor < v"11.8" && platform["cuda_platform"] == "jetson"
            return false
        end
        if minor == v"12.3" && platform["cuda_platform"] == "jetson"
            return false
        end
        return true
    end

    return platforms
end

# determine exactly which tarballs we should build
builds = []
for version in header_versions
    for platform in get_platforms(version)
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(version)
        should_build_platform(triplet(augmented_platform)) || continue

        if Base.thisminor(version) == v"10.2"
            # our CUDA 10.2 SDK build only provides Jetson binaries on aarch64
            if arch(platform) == "aarch64" && platform["cuda_platform"] != "jetson"
                continue
            end
            push!(builds,
                (; script=get_script(), platforms=[augmented_platform], products=get_products(),
                   sources=[],
                   dependencies=[dependencies;
                                 BuildDependency(PackageSpec(name="CUDA_SDK_jll", version="10.2.89"))],
            ))
        else
            push!(builds,
                (; script, platforms=[augmented_platform], products, dependencies,
                   sources=get_sources("cuda", ["cuda_cudart"]; version, platform=augmented_platform),
            ))
        end
    end
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` and `--deploy` should only be passed to the final `build_tarballs` invocation
non_reg_ARGS = filter(non_platform_ARGS) do arg
    arg != "--register" && !startswith(arg, "--deploy")
end

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, build.products, build.dependencies;
                   julia_compat="1.10", lazy_artifacts=true,
                   augment_platform_block=CUDA.compiler_augment)
end
