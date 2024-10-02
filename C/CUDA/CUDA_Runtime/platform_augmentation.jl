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

if ismissing(version_preference)
    # before loading CUDA_Driver_jll, try to find out where the system driver is located.
    let
        name = if Sys.iswindows()
            Libdl.find_library("nvcuda")
        else
            Libdl.find_library(["libcuda.so.1", "libcuda.so"])
        end

        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
        if name != ""
            handle = Libdl.dlopen(name)
            path = Libdl.dlpath(handle)
            Libdl.dlclose(handle)

            @debug "Adding include dependency on $path"
            Base.include_dependency(path)
        end
    end
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

# get the version of the available CUDA driver by querying either CUDA_Driver_jll's
# driver, or the system driver if CUDA_Driver_jll is not available
function get_driver_version()
    if !@isdefined(CUDA_Driver_jll)
        # driver JLL not available because we're in the middle of installing packages
        @debug "CUDA_Driver_jll not available; not selecting an artifact"
        return nothing
    end

    cuda_driver = if CUDA_Driver_jll.is_available()
        @debug "Using CUDA_Driver_jll for driver discovery"

        if !isdefined(CUDA_Driver_jll, :libcuda) || # CUDA_Driver_jll@0.4-compat
            isnothing(CUDA_Driver_jll.libcuda)      # https://github.com/JuliaLang/julia/issues/48999
            # no driver found
            @debug "CUDA_Driver_jll reports no driver found"
            return nothing
        end
        CUDA_Driver_jll.libcuda
    else
        # CUDA_Driver_jll only kicks in for supported platforms, so fall back to
        # a system search if the artifact isn't available (JLLWrappers.jl#50)
        @debug "CUDA_Driver_jll unavailable, falling back to system search"

        driver_name = if Sys.iswindows()
            Libdl.find_library("nvcuda")
        else
            Libdl.find_library(["libcuda.so.1", "libcuda.so"])
        end
        if driver_name == ""
            # no driver found
            @debug "CUDA_Driver_jll unavailable, and no system CUDA driver found"
            return nothing
        end

        driver_name
    end
    @debug "Found CUDA driver at '$cuda_driver'"

    # minimal API call wrappers we need
    function cuDriverGetVersion(library_handle)
        function_handle = Libdl.dlsym(library_handle, "cuDriverGetVersion"; throw_error=false)
        if function_handle === nothing
            @debug "Driver library seems invalid (does not contain 'cuDriverGetVersion')"
            return nothing
        end
        version_ref = Ref{Cint}()
        status = ccall(function_handle, Cint, (Ptr{Cint},), version_ref)
        if status != 0
            @debug "Call to 'cuDriverGetVersion' failed with status $status"
            return nothing
        end
        major, ver = divrem(version_ref[], 1000)
        minor, patch = divrem(ver, 10)
        return VersionNumber(major, minor, patch)
    end

    driver_handle = Libdl.dlopen(cuda_driver; throw_error=false)
    if driver_handle === nothing
        @debug "Failed to load CUDA driver"
        return nothing
    end

    cuDriverGetVersion(driver_handle)
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

    # if not, we need to be able to use the driver to determine the version.
    # note that we only require this when there's no override, to support
    # precompiling with a fixed version without having the driver available.
    if !@isdefined(cuda_version_override)
        cuda_driver_version = get_driver_version()
        if cuda_driver_version === nothing
            @debug "Failed to query CUDA driver version"
            return nothing
        end
        @debug "CUDA driver version: $cuda_driver_version"
    end

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    compatible_toolkits = filter(cuda_toolkits) do toolkit
        if @isdefined(cuda_version_override)
            thisminor(toolkit) == thisminor(cuda_version_override)
        elseif cuda_driver_version >= v"11"
            # enhanced compatibility
            #
            # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
            #  from within a CUDA major release family can run, with limited feature-set,
            #  on systems having at least the minimum required driver version"
            thismajor(toolkit) <= thismajor(cuda_driver_version)
        else
            thisminor(toolkit) <= thisminor(cuda_driver_version)
        end
    end
    if isempty(compatible_toolkits)
        # the user either has a functional CUDA driver set-up, or requested a specific
        # toolkit version, so complain loudly if we aren't compatible with it.
        if @isdefined(cuda_version_override)
            @error "Requested CUDA version $(cuda_version_override) does not match any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
        else
            @error "CUDA driver $(cuda_driver_version) is not compatible with any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
        end
        return nothing
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
