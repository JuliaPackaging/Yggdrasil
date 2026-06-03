module ROCm

using Pkg

using BinaryBuilder

using Base.BinaryPlatforms
using Base.BinaryPlatforms: arch, os, tags

# the "rocm_platform" platform tag contains the GPU architecture (e.g., "gfx103X-dgpu")
# detected by querying the HSA runtime, and is used to select artifacts that depend on ROCm.

const augment = """
    using Base.BinaryPlatforms

    try
        using rocm_sdk_core_jll
    catch
        # during initial package installation, rocm_sdk_core_jll may not be available.
        # in that case, we just won't select an artifact.
    end

    # can't use Preferences for the same reason
    const rocm_sdk_core_jll_uuid = Base.UUID("9ab9228b-5f62-5ec0-95ae-72487824505f")
    const preferences = Base.get_preferences(rocm_sdk_core_jll_uuid)
    Base.record_compiletime_preference(rocm_sdk_core_jll_uuid, "local")
    const local_toolkit = something(tryparse(Bool, get(preferences, "local", "false")), false)

    function rocm_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
        # if we're using a local toolkit, we can't use artifacts
        if local_toolkit
            return false
        end
        return a == b
    end

    function augment_platform!(platform::Platform)
        if !@isdefined(rocm_sdk_core_jll)
            # don't set to nothing or Pkg will download any artifact
            platform["rocm_platform"] = "none"
        end

        if !haskey(platform, "rocm_platform")
            rocm_sdk_core_jll.augment_platform!(platform)
        end
        BinaryPlatforms.set_compare_strategy!(platform, "rocm_platform", rocm_comparison_strategy)

        return platform
    end"""

# Known ROCm GPU architectures
const rocm_platforms = [
    "gfx101x_dgpu",
    "gfx103x_dgpu",
    "gfx110x_all",
    #"gfx110x_dgpu",
    "gfx1150",
    "gfx1151",
    "gfx120x_all",
    "gfx90x_dcgpu",
    "gfx94x_dcgpu",
    "gfx950_dcgpu",
]

"""
    supported_platforms(; platforms=rocm_platforms)

Return a list of supported platforms to build ROCm artifacts for.

# Arguments
- `platforms=rocm_platforms`: List of ROCm GPU architectures to target.
"""
function supported_platforms(; platforms=rocm_platforms)
    base_platforms = [
        Platform("x86_64", "linux"; libc = "glibc", cxxstring_abi = "cxx11"),
    ]

    # augment with ROCm platforms
    result = Platform[]
    for base_platform in base_platforms
        for rocm_platform in platforms
            platform = deepcopy(base_platform)
            platform["rocm_platform"] = rocm_platform
            push!(result, platform)
        end
    end

    return result
end

"""
    is_supported(platform)

Check if a platform is supported by ROCm, and whether we can build artifacts for it.
"""
function is_supported(platform)
    return Sys.islinux(platform) && arch(platform) == "x86_64"
end

"""
    required_dependencies(platform)

Return a list of dependencies required to build and use ROCm artifacts for a given platform.
"""
function required_dependencies(platform)
    if !haskey(tags(platform), "rocm_platform") || tags(platform)["rocm_platform"] == "none"
        return BinaryBuilder.AbstractDependency[]
    end

    return BinaryBuilder.AbstractDependency[
        RuntimeDependency(PackageSpec(name="rocm_sdk_core_jll"))
    ]
end

end
