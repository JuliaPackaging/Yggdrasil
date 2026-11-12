# NOTE: this file is preceded by `toolkit_selection.jl` (shared with CUDA_Runtime_jll).

function augment_platform!(platform::Platform)
    if !haskey(platform, "cuda")
        # use "none" when no CUDA toolkit could be selected (no driver, no preference), just
        # like CUDA_Runtime_jll does. This makes `is_available()` false, instead of selecting
        # a (lazy) artifact whose libraries would then be eagerly dlopen'ed at load time on
        # a system that cannot use them (JuliaGPU/CUDA.jl#3242). Systems without a GPU that
        # want to precompile or cross-compile should set the version preference explicitly.
        # We can't just leave off the platform tag or Pkg would select *any* artifact.
        platform["cuda"] = something(cuda_toolkit_tag(), "none")
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
