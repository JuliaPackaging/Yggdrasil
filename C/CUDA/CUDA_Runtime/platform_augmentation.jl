# NOTE: this file is preceded by `toolkit_selection.jl` (shared with CUDA_Compiler_jll),
#       which provides `cuda_toolkit_tag()`, `cuda_comparison_strategy`,
#       `local_preference`, and `is_tegra()`.

function augment_platform!(platform::Platform)
    if !haskey(platform, "cuda")
        platform["cuda"] = something(cuda_toolkit_tag(), "none")
        # XXX: use "none" when we couldn't find a compatible toolkit.
        #      we can't just leave off the platform tag or Pkg would select *any* artifact.
    end
    BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)

    # store the fact that we're using a local CUDA toolkit, so that we can more easily
    # query it from CUDA.jl without having to parse the preference again.
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
