module CUDA

# the "cuda" platform tag contains the major and minor version of the CUDA runtime loaded
# by CUDA_Runtime_jll, and is used to select artifacts that depend on the CUDA runtime.

const platform_name = "cuda"
const augment = """
    using CUDA_Runtime_jll

    function cuda_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
        a = VersionNumber(a)
        b = VersionNumber(b)

        # If both b and a requested, then we fall back to equality:
        if a_requested && b_requested
            return a == b
        end

        # Otherwise, do the comparison between the the single version cap and the single version:
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            if host >= v"11.0"
                # enhanced compatibility, semver-style
                artifact.major == host.major
            else
                artifact.major == host.major &&
                artifact.minor == host.minor
            end
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_platform!(platform::Platform)
        set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)
        haskey(platform, "cuda") && return platform
        CUDA_Runtime_jll.augment_platform!(platform)
    end"""

function platform(cuda::VersionNumber)
    return "$(cuda.major).$(cuda.minor)"
end

end
