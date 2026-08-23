# CUDA toolkit selection logic, shared between the platform augmentation blocks of
# CUDA_Runtime_jll and CUDA_Compiler_jll. The including build recipe must prepend a
# `CUDA_jll_uuids` list (preference namespaces, in decreasing order of priority),
# append `cuda_toolkits` and `cuda_prerelease_toolkits`, and append an
# `augment_platform!` implementation.
#
# The driver-dependent parts of the selection -- inspecting the driver and its devices,
# and the capability database -- live in CUDA_Driver_jll's toplevel block; see
# `select_cuda_toolkit` there. Only what must keep working when that package cannot be
# loaded (which can happen during initial installation, cf. JuliaLang/Pkg.jl#3225) is
# inlined here: preference handling, and the version-override and local-toolkit paths,
# so that precompiling with a fixed version works without CUDA_Driver_jll or a driver.

using Base.BinaryPlatforms

using Base: thismajor, thisminor

using Libdl

# read the preferences from the first UUID that has any CUDA selection preference set;
# namespaces are not merged, to avoid mixing related preferences from different sources.
# all namespaces are recorded regardless, so the precompilation cache is invalidated
# when a higher-priority namespace gains a preference later.
#
# we can't use Preferences.jl here, for the same manifest-related reasons we can't
# rely on CUDA_Driver_jll (see above).
const preferences = let
    selected = nothing
    for uuid in CUDA_jll_uuids
        Base.record_compiletime_preference(uuid, "version")
        Base.record_compiletime_preference(uuid, "local")
        prefs = Base.get_preferences(uuid)
        if selected === nothing &&
           any(key -> haskey(prefs, key), ["version", "local", "actual_version"])
            selected = prefs
        end
    end
    something(selected, Dict{String,Any}())
end

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
# because of that, we need to be very careful about using that dependency: guard the
# import, and treat any error calling into it (including UndefVarError from versions
# predating the selection library) as "no selection possible".
#
# ref: https://github.com/JuliaLang/Pkg.jl/issues/3225
try
    using CUDA_Driver_jll
catch err
    # handled in cuda_toolkit_tag below
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

    # with a version override, we don't need to (and shouldn't) inspect the driver:
    # this supports precompiling with a fixed version without a driver available.
    if @isdefined(cuda_version_override)
        compatible_toolkits =
            filter(toolkit -> thisminor(toolkit) == thisminor(cuda_version_override),
                   cuda_toolkits)
        if isempty(compatible_toolkits)
            @error "Requested CUDA version $(cuda_version_override) does not match any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
            return nothing
        end
        cuda_toolkit = thisminor(last(compatible_toolkits))
        @debug "Selected CUDA toolkit: $cuda_toolkit"
        return "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
    end

    # otherwise, delegate to CUDA_Driver_jll, which inspects the driver to determine its
    # version and the compute capability of each visible device.
    cuda_toolkit = try
        CUDA_Driver_jll.select_cuda_toolkit(cuda_toolkits, cuda_prerelease_toolkits)
    catch err
        # CUDA_Driver_jll not loadable, a version predating the selection library,
        # or driver inspection went wrong: don't select an artifact.
        @debug "Could not select a CUDA toolkit through CUDA_Driver_jll" exception=err
        return nothing
    end
    cuda_toolkit === nothing && return nothing
    return "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
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
