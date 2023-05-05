module CUDA

# the "cuda" platform tag contains the major and minor version of the CUDA runtime loaded
# by CUDA_Runtime_jll, and is used to select artifacts that depend on the CUDA runtime.

const platform_name = "cuda"
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
    v"11.0.3",
    v"11.1.1",
    v"11.2.2",
    v"11.3.1",
    v"11.4.4",
    v"11.5.2",
    v"11.6.2",
    v"11.7.1",
    v"11.8.0",
    v"12.0.1",
    v"12.1.1"
]
function full_version(cuda::VersionNumber)
    haskey(cuda_full_versions, cuda) || error("CUDA version $cuda not supported")
    return cuda_full_versions[cuda]
end

end
