using Base.BinaryPlatforms

using Base: thismajor, thisminor

using Libdl

const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)
Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")
Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "local")
const local_preference = if haskey(preferences, "local")
    if isa(preferences["local"], Bool)
        preferences["local"]
    elseif isa(preferences["local"], String)
        use_local = tryparse(Bool, preferences["local"])
        if use_local === nothing
            @error "CUDA local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
            missing
        else
            use_local
        end
    else
        @error "CUDA local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
        missing
    end
elseif haskey(preferences, "version") && preferences["version"] == "local"
    # legacy support for CUDA.jl's old "version" preference format.
    # in this case, an "actual_version" preference is required.
    @debug "The version=local preference is deprecated, please use local=true instead."
    # XXX: turn this into a warning after HPC people have had the time to upgrade.
    true
else
    missing
end

function parse_version_preference(key)
    if haskey(preferences, key)
        if isa(preferences[key], String)
            version = tryparse(VersionNumber, preferences[key])
            if version === nothing
                @error "CUDA $key preference is not valid; expected a version number, but got '$(preferences[key])'"
                missing
            else
                version
            end
        else
            @error "CUDA $key preference is not valid; expected a version number, but got '$(preferences[key])'"
            missing
        end
    else
        missing
    end
end
const version_preference = if haskey(preferences, "version") && preferences["version"] == "local"
    # legacy support for CUDA.jl's old "version" preference format.
    # in this case, an "actual_version" preference is required.
    parse_version_preference("actual_version")
else
    parse_version_preference("version")
end

# platform augmentation hooks run in an ill-defined environment, where:
# - CUDA_Driver_jll may not be available
# - the wrong version of CUDA_Driver_jll may be available
#
# because of that, we need to be very careful about using that dependency.
# currently, we support all existing versions of CUDA_Driver_jll, but if we
# ever need to introduce a breaking change, we'll need some way to identify
# the version of CUDA_Driver_jll from its module (e.g. a global constant).
#
# ref: https://github.com/JuliaLang/Pkg.jl/issues/3225
# can't use Preferences for the same reason
try
    using CUDA_Driver_jll
catch err
    # we'll handle this below
end

# get the version of the local CUDA toolkit by querying the system libcudart
function get_runtime_version()
    cuda_runtime = if Sys.iswindows()
        Libdl.find_library(["cudart64_12", "cudart64_110"])
    else
        Libdl.find_library(["libcudart.so", "libcudart.so.12", "libcudart.so.11.0"])
    end
    if cuda_runtime == ""
        # no runtime library found
        @debug "No system CUDA runtime library found"
        return nothing
    end
    @debug "Found CUDA runtime library at '$cuda_runtime'"

    # minimal API call wrappers we need
    function cudaRuntimeGetVersion(library_handle)
        function_handle = Libdl.dlsym(library_handle, "cudaRuntimeGetVersion"; throw_error=false)
        if function_handle === nothing
            @debug "Runtime library seems invalid (does not contain 'cudaRuntimeGetVersion')"
            return nothing
        end
        version_ref = Ref{Cint}()
        status = ccall(function_handle, Cint, (Ptr{Cint},), version_ref)
        if status != 0
            @debug "Call to 'cudaRuntimeGetVersion' failed with status $status"
            return nothing
        end
        major, ver = divrem(version_ref[], 1000)
        minor, patch = divrem(ver, 10)
        return VersionNumber(major, minor, patch)
    end

    runtime_handle = Libdl.dlopen(cuda_runtime; throw_error=false)
    if runtime_handle === nothing
        @debug "Failed to load CUDA runtime library"
        return nothing
    end

    cudaRuntimeGetVersion(runtime_handle)
end

# get the CUDA driver version and the compute capability of each visible device
# by invoking CUDA_Driver_jll's `inspect_driver` helper, which runs the inspection
# in a subprocess so we don't have to load the driver into our own process.
function get_driver_info()
    if !@isdefined(CUDA_Driver_jll)
        # driver JLL not available because we're in the middle of installing packages
        @debug "CUDA_Driver_jll not available; not selecting an artifact"
        return nothing
    end

    if !CUDA_Driver_jll.is_available()
        # CUDA_Driver_jll only kicks in for supported platforms (JLLWrappers.jl#50).
        # without it we can't inspect device capabilities, so bail out rather than
        # risk picking a toolkit that ends up being incompatible with the hardware.
        @debug "CUDA_Driver_jll not available on this platform; not selecting an artifact"
        return nothing
    end

    if !isdefined(CUDA_Driver_jll, :inspect_driver)
        # the inspect_driver helper was added in a later CUDA_Driver_jll release.
        @debug "CUDA_Driver_jll does not provide the inspect_driver helper; not selecting an artifact"
        return nothing
    end

    # inspect the system driver (rather than CUDA_Driver_jll's chosen libcuda,
    # which may be the forward-compatible driver bundled in its artifact). only
    # the system driver actually changes when the user upgrades their NVIDIA
    # driver, and it's the one we want to depend on for cache invalidation.
    libcuda_system = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"

    # platform augmentation runs in a Pkg subprocess where the in-memory
    # manifest may be inconsistent (JuliaLang/Pkg.jl#3225), so the version of
    # CUDA_Driver_jll we just loaded may have a `inspect_driver` whose
    # signature, return shape, or behaviour doesn't match what we expect.
    # treat any failure (signature mismatch, missing field access, etc.) the
    # same as an unavailable inspector and bail out.
    info = try
        CUDA_Driver_jll.inspect_driver(libcuda_system; inspect_devices=true)
    catch err
        @debug "CUDA_Driver_jll.inspect_driver failed: $err"
        return nothing
    end
    info === nothing && return nothing

    path, version, capabilities = try
        info.path, info.version, info.capabilities
    catch err
        @debug "CUDA_Driver_jll.inspect_driver returned an unexpected value: $err"
        return nothing
    end

    # register the resolved driver path as an include dependency so our
    # precompile cache is invalidated when the user upgrades their driver.
    @debug "Adding include dependency on $path"
    Base.include_dependency(path)

    return (version, capabilities)
end

# CUDA toolkit support for each GPU compute capability. Maps a compute
# capability to a `(lo, hi)` tuple of inclusive toolkit version bounds:
# `lo` is the toolkit that introduced support for the architecture, `hi` is
# the last toolkit that still supports it (toolkits drop architecture support
# over time). `v"99"` is used as an open-ended upper bound for capabilities
# still supported by current toolkits.
#
# Sources:
# - https://en.wikipedia.org/wiki/CUDA#GPUs_supported
# - `ptxas |& grep -A 10 '\--gpu-name'`
const cuda_cap_db = Dict{VersionNumber, NTuple{2, VersionNumber}}(
    v"1.0"   => (v"0",     v"6.5"),
    v"1.1"   => (v"0",     v"6.5"),
    v"1.2"   => (v"0",     v"6.5"),
    v"1.3"   => (v"0",     v"6.5"),
    v"2.0"   => (v"0",     v"8.0"),
    v"2.1"   => (v"0",     v"8.0"),
    v"3.0"   => (v"4.2",   v"10.2"),
    v"3.2"   => (v"6.0",   v"10.2"),
    v"3.5"   => (v"5.0",   v"11.8"),
    v"3.7"   => (v"6.5",   v"11.8"),
    v"5.0"   => (v"6.0",   v"12.9"),
    v"5.2"   => (v"7.0",   v"12.9"),
    v"5.3"   => (v"7.5",   v"12.9"),
    v"6.0"   => (v"8.0",   v"12.9"),
    v"6.1"   => (v"8.0",   v"12.9"),
    v"6.2"   => (v"8.0",   v"12.9"),
    v"7.0"   => (v"9.0",   v"12.9"),
    v"7.2"   => (v"9.2",   v"12.9"),
    v"7.5"   => (v"10.0",  v"99"),
    v"8.0"   => (v"11.0",  v"99"),
    v"8.6"   => (v"11.1",  v"99"),
    v"8.7"   => (v"11.4",  v"99"),
    v"8.9"   => (v"11.8",  v"99"),
    v"9.0"   => (v"11.8",  v"99"),
    v"10.0"  => (v"12.8",  v"99"),
    v"10.3"  => (v"12.8",  v"99"),
    v"11.0"  => (v"12.8",  v"99"),
    v"12.0"  => (v"12.8",  v"99"),
    v"12.1"  => (v"12.9",  v"99"),
)

"""
    supported_capabilities(toolkit::VersionNumber) -> Set{VersionNumber}

Return the set of GPU compute capabilities supported by the given CUDA toolkit.
Comparisons are at minor-version granularity, so e.g. `v"12.9.1"` and `v"12.9.0"`
are treated identically.
"""
function supported_capabilities(toolkit::VersionNumber)
    minor = thisminor(toolkit)
    Set(cap for (cap, (lo, hi)) in cuda_cap_db if lo <= minor <= hi)
end

# returns the value for the "cuda" tag we should use in the platform ("$MAJOR.$MINOR")
# or nothing if no compatible CUDA toolkit was found.
function cuda_toolkit_tag()
    # check if the user requested a specific version
    if version_preference !== missing
        @debug "CUDA version override: $version_preference"
        cuda_version_override = version_preference
    end

    # check if the user requested to use a local version
    if local_preference !== missing
        @debug "CUDA local preference: $(local_preference)"
        if local_preference && !@isdefined(cuda_version_override)
            # the user didn't specify a version, so try quering it
            version = get_runtime_version()
            if version === nothing
                @error """Local CUDA version requested, but could not query the runtime version.
                          Either make sure CUDA is available, or set the CUDA version explicitly."""
                return nothing
            end
            @debug "Local CUDA runtime version: $version"
            cuda_version_override = version
        end

        # if we're using a local toolkit, use the version as-is. this may result in an
        # incompatible toolkit being used, but CUDA.jl will complain about that.
        if local_preference
            return "$(cuda_version_override.major).$(cuda_version_override.minor)"
        end
    end

    # if not, we need to be able to inspect the driver to determine its version
    # and the compute capability of each visible device. we only require this
    # when there's no override, to support precompiling with a fixed version
    # without having the driver available.
    if !@isdefined(cuda_version_override)
        driver_info = get_driver_info()
        if driver_info === nothing
            @debug "Failed to query the CUDA driver and its devices"
            return nothing
        end
        cuda_driver_version, device_capabilities = driver_info
        @debug "CUDA driver version: $cuda_driver_version"
        if isempty(device_capabilities)
            @debug "No CUDA devices visible"
        else
            @debug "CUDA device compute capabilities: $(join(device_capabilities, ", "))"
        end
    end

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    compatible_toolkits = filter(cuda_toolkits) do toolkit
        if @isdefined(cuda_version_override)
            return thisminor(toolkit) == thisminor(cuda_version_override)
        end

        # enhanced compatibility
        #
        # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
        #  from within a CUDA major release family can run, with limited feature-set,
        #  on systems having at least the minimum required driver version"
        if cuda_driver_version >= v"11"
            thismajor(toolkit) <= thismajor(cuda_driver_version)
        else
            thisminor(toolkit) <= thisminor(cuda_driver_version)
        end
    end
    if isempty(compatible_toolkits)
        if @isdefined(cuda_version_override)
            @error "Requested CUDA version $(cuda_version_override) does not match any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
        else
            @error "CUDA driver $(cuda_driver_version) is not compatible with any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
        end
        return nothing
    end

    # narrow the candidate toolkits to those that support the user's hardware,
    # giving priority to the newest devices: walk device capabilities from
    # newest to oldest, intersecting the candidate set with toolkits supporting
    # each. if an older device cannot be supported alongside newer ones, drop
    # it rather than discard the whole selection, as the user almost certainly
    # cares more about their newest hardware working than their oldest.
    if !@isdefined(cuda_version_override) && !isempty(device_capabilities)
        supports_capability(toolkit, cap) = let minor = thisminor(toolkit)
            # capabilities absent from `cuda_cap_db` are presumed unsupported:
            # they're either future architectures that need a newer toolkit
            # than anything we know about, or fictional. either way no toolkit
            # in our list is known to handle them.
            haskey(cuda_cap_db, cap) || return false
            lo, hi = cuda_cap_db[cap]
            lo <= minor <= hi
        end
        for cap in sort(unique(device_capabilities); rev=true)
            subset = filter(t -> supports_capability(t, cap), compatible_toolkits)
            if isempty(subset)
                @debug "No remaining toolkit supports device with compute capability $cap; dropping it from the selection"
            else
                compatible_toolkits = subset
            end
        end
    end

    cuda_toolkit = Base.thisminor(last(compatible_toolkits))
    @debug "Selected CUDA toolkit: $cuda_toolkit"
    "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
end

function cuda_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    # we don't actually need a comparison strategy, as the tag is known to exactly match
    # whatever toolkit artifacts we have available. however, we use one so that we can
    # bail out from downloading artifacts if the user requested a local toolkit
    if local_preference !== missing && local_preference
        return false
    end

    return a == b
end

function is_tegra()
    if isfile("/etc/nv_tegra_release")
        return true
    end
    if isfile("/proc/device-tree/compatible") &&
        contains(read("/proc/device-tree/compatible", String), "tegra")
        return true
    end
    return false
end

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
