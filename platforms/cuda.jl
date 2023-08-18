module CUDA

using Pkg

using BinaryBuilder

using Base.BinaryPlatforms
using Base.BinaryPlatforms: arch, os, tags

# the "cuda" platform tag contains the major and minor version of the CUDA runtime loaded
# by CUDA_Runtime_jll, and is used to select artifacts that depend on the CUDA runtime.

const augment = """
    using Base.BinaryPlatforms

    try
        using CUDA_Runtime_jll
    catch
        # during initial package installation, CUDA_Runtime_jll may not be available.
        # in that case, we just won't select an artifact.
    end

    function cuda_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
        if a == "none" || b == "none"
            return a == b
        end
        if a == "local" || b == "local"
            return a == b
        end
        a = VersionNumber(a)
        b = VersionNumber(b)

        # If both b and a requested, then we fall back to equality:
        if a_requested && b_requested
            return Base.thisminor(a) == Base.thisminor(b)
        end

        # Otherwise, do the comparison between the the single version cap and the single version:
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            if host >= v"11.0"
                # enhanced compatibility, semver-style
                artifact.major == host.major &&
                Base.thisminor(artifact) <= Base.thisminor(host)
            else
                Base.thisminor(artifact) == Base.thisminor(host)
            end
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_platform!(platform::Platform)
        if !@isdefined(CUDA_Runtime_jll)
            # don't set to nothing or Pkg will download any artifact
            platform["cuda"] = "none"
        end

        if !haskey(platform, "cuda")
            CUDA_Runtime_jll.augment_platform!(platform)
        end
        BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)
        return platform
    end"""

function platform(cuda::VersionNumber)
    return "$(cuda.major).$(cuda.minor)"
end
platform(cuda::String) = cuda

# BinaryBuilder.jl currently does not allow selecting a BuildDependency by compat,
# so we need the full version for CUDA_full_jll (JuliaPackaging/BinaryBuilder.jl#/1212).
const cuda_full_versions = [
    v"11.4.4",
    v"11.5.2",
    v"11.6.2",
    v"11.7.1",
    v"11.8.0",
    v"12.0.1",
    v"12.1.1",
    v"12.2.1",
]
function full_version(ver::VersionNumber)
    ver == Base.thisminor(ver) || error("Cannot specify a patch version")
    for full_ver in cuda_full_versions
        if ver == Base.thisminor(full_ver)
            return full_ver
        end
    end
    error("CUDA version $ver not supported")
end

"""
    supported_platforms()

Return a list of supported platforms to build CUDA artifacts for.
"""
function supported_platforms()
    base_platforms = [
        Platform("x86_64", "linux"; libc = "glibc"),
        Platform("aarch64", "linux"; libc = "glibc"),
        Platform("powerpc64le", "linux"; libc = "glibc"),

        # nvcc isn't a cross compiler, so incompatible with BinaryBuilder
        #Platform("x86_64", "windows"),
    ]

    # augment with CUDA versions
    platforms = Platform[]
    for version in cuda_full_versions
        for base_platform in base_platforms
            platform = deepcopy(base_platform)
            platform["cuda"] = "$(version.major).$(version.minor)"
            push!(platforms, platform)
        end
    end

    return platforms
end

"""
    is_supported(platform)

Check if a platform is supported by CUDA, and whether we can build artifacts for it.
This can be used to determine whether to also provide a `cuda+none` build, which should
only ever be used if there is _also_ a CUDA-enabled build available.
"""
function is_supported(platform)
    if Sys.islinux(platform)
        return arch(platform) in ["x86_64", "aarch64", "powerpc64le"]
    elseif is Sys.iswindows(platform)
        # see note in `supported_platforms()`
        return false
    else
        return false
    end
end

"""
    required_dependencies(platform)

Return a list of dependencies required to build and use CUDA artifacts for a given platform.
"""
function required_dependencies(platform)
    dependencies = Dependency[]
    if !haskey(tags(platform), "cuda") || tags(platform)["cuda"] == "none"
        return BinaryBuilder.AbstractDependency[]
    end
    release = VersionNumber(tags(platform)["cuda"])
    return BinaryBuilder.AbstractDependency[
        BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(release))),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))
    ]
end

end
