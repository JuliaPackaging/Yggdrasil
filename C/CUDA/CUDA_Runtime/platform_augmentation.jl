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

# For JLLs whose builds follow our toolkit selection: the platform augmentation block they
# embed (`CUDA.augment` in Yggdrasil) calls this, so that a release of this package fixes
# the selection logic for all of them without rebuilding them. Keep the signature stable.
#
# Copies our selection into `platform`. If `artifacts_toml` has no build for it and the
# platform's other tags, which must be set already, selects the `cuda=none` build instead.
# A `cuda` tag that is already set is an explicit request, and is kept as is.
import Artifacts

function augment_dependent!(platform::Platform, artifacts_toml::String)
    explicit = haskey(platform, "cuda")
    if !explicit
        for tag in ("cuda", "cuda_local", "cuda_platform")
            haskey(host_platform, tag) && (platform[tag] = host_platform[tag])
        end
    end
    BinaryPlatforms.set_compare_strategy!(platform, "cuda", dependent_comparison_strategy)
    explicit && return platform

    if platform["cuda"] != "none" && isfile(artifacts_toml) &&
       isempty(Artifacts.select_downloadable_artifacts(artifacts_toml; platform,
                                                       include_lazy=true))
        platform["cuda"] = "none"
    end
    return platform
end

# a dependent's `cuda=X.Y` build needs our toolkit X.Y, or, from CUDA 11, a newer minor
# of the same major
function dependent_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    av = tryparse(VersionNumber, a)
    bv = tryparse(VersionNumber, b)
    (av === nothing || bv === nothing) && return a == b

    # CUDA builds need our toolkit, which a local toolkit replaces
    local_preference === true && return false

    a_requested && b_requested && return thisminor(av) == thisminor(bv)
    build, host = a_requested ? (bv, av) : (av, bv)
    if host >= v"11"
        build.major == host.major && thisminor(build) <= thisminor(host)
    else
        thisminor(build) == thisminor(host)
    end
end

# The toolkit selection is baked into the precompilation cache, which only depends on the
# driver if one could be loaded. A cache made without one, e.g. on an HPC login node, thus
# stays in use on GPU nodes sharing the depot. Recompiling there would make both kinds of
# host recompile against each other, so warn instead. This is a submodule because the
# package has no `__init__` when no artifact was selected.
module SelectionCheck

using Libdl
using Base.BinaryPlatforms: Platform, tags

function check(jll)
    # only when loaded, not while precompiling dependents
    Base.JLOptions().incremental == 0 || return
    # these preferences make the selection independent of the driver
    (jll.cuda_disabled || jll.version_preference !== missing || jll.local_preference === true) && return
    tags(jll.host_platform::Platform)["cuda"] == "none" || return

    handle = Libdl.dlopen_e(jll.CUDA_Driver_jll.libcuda::String)
    handle == C_NULL && return
    driver = jll.get_driver_version(handle)
    driver === nothing && return
    toolkits = jll.driver_compatible_toolkits(driver, jll.cuda_toolkits,
                                              jll.cuda_prerelease_toolkits)
    isempty(toolkits) && return
    version = "$(last(toolkits).major).$(last(toolkits).minor)"

    origin = get(Base.pkgorigins, Base.PkgId(jll), nothing)
    compiled = if origin === nothing || origin.cachepath === nothing
        "the `compiled` directory of your depot"
    else
        dirname(dirname(origin.cachepath))
    end
    @warn """CUDA_Runtime_jll was precompiled without an NVIDIA driver, but this system has one.
             Packages that depend on it use their CPU builds, or no CUDA at all.
             This happens when systems with and without a driver share a depot. To select
             the same toolkit on all of them, call e.g. `CUDA.set_runtime_version!(v"$version")`,
             or set `version = "$version"` for CUDA_Runtime_jll and CUDA_Compiler_jll in your
             LocalPreferences.toml; for a whole cluster, see
             https://cuda.juliagpu.org/stable/installation/overview/#Shared-depots.
             Or, to select one for this system, delete the CUDA_Runtime_jll and
             CUDA_Compiler_jll directories in $compiled and restart Julia."""
end

function __init__()
    jll = parentmodule(@__MODULE__)
    # Pkg's artifact selection includes this file into `Main` of a separate process
    isdefined(jll, :host_platform) || return
    try
        check(jll)
    catch err
        @debug "Could not check the CUDA toolkit selection" exception=(err, catch_backtrace())
    end
end

# JLLs run interpreted; keep the check from compiling at load time
precompile(check, (Module,))

end
