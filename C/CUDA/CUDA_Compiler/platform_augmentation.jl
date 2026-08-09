# NOTE: this file is preceded by `toolkit_selection.jl` (shared with CUDA_Runtime_jll).

function augment_platform!(platform::Platform)
    if !haskey(platform, "cuda")
        default_tag = "$(cuda_default_toolkit.major).$(cuda_default_toolkit.minor)"
        platform["cuda"] = something(cuda_toolkit_tag(), default_tag)
    end
    BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)

    platform["cuda_local"] = string(local_preference !== missing && local_preference)

    # if we're on an arm64 platform, identify the CUDA subplatform
    if Sys.islinux() && arch(platform) == "aarch64"
        platform["cuda_platform"] = if is_tegra()
            "jetson"
        else
            "sbsa"
        end
    end

    return platform
end
