using Base.BinaryPlatforms

using Base: thismajor, thisminor

using Libdl

try
    using CUDA_Driver_jll
catch err
    # during initial package installation, CUDA_Driver_jll may not be available.
    # in that case, we just won't select an artifact (unless the user has set a preference).
end

# Can't use Preferences for the same reason
const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)
Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")

# returns the value for the "cuda" tag we should use in the platform.
# possible values:
#  - "$MAJOR.$MINOR": a VersionNumber-like string
#  - "local": the user has requested to use the local CUDA installation
#  - "none": no compatible CUDA toolkit was found.
#    note that we don't just leave off the platform tag or Pkg would select *any* artifact.
function cuda_toolkit_tag()
    # check if the user requested a specific version
    if haskey(preferences, "version") && isa(preferences["version"], String)
        @debug "CUDA version override: $(preferences["version"])"
        version = tryparse(VersionNumber, preferences["version"])
        if version === nothing
            @debug "CUDA version override is not a valid version number; returning as-is"
            return preferences["version"]
        end
        cuda_version_override = version
    end

    # if not, we need to be able to use the driver to determine the version.
    # note that we only require this when there's no override, to support
    # precompiling with a fixed version without having the driver available.
    if !@isdefined(cuda_version_override)
        if !@isdefined(CUDA_Driver_jll)
            # driver JLL not available because we're in the middle of installing packages
            @debug "CUDA_Driver_jll not available; not selecting an artifact"
            return "none"
        end

        cuda_driver = if CUDA_Driver_jll.is_available()
            @debug "Using CUDA_Driver_jll for driver discovery"

            if isnothing(CUDA_Driver_jll.libcuda)
                # no driver found
                @debug "CUDA_Driver_jll reports no driver found"
                return "none"
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
                return "none"
            end

            driver_name
        end
        @debug "Found CUDA driver at '$cuda_driver'"

        # minimal API call wrappers we need
        function driver_version(library_handle)
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
            return "none"
        end

        cuda_driver_version = driver_version(driver_handle)
        if cuda_driver_version === nothing
            @debug "Failed to query CUDA driver version"
            return "none"
        end

        @debug "CUDA driver version: $cuda_driver_version"
    end

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    filter!(cuda_toolkits) do toolkit
        if @isdefined(cuda_version_override)
            toolkit == cuda_version_override
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
    if isempty(cuda_toolkits)
        @debug "No compatible CUDA toolkit found"
        return "none"
    end

    cuda_toolkit = last(cuda_toolkits)
    @debug "Selected CUDA toolkit: $cuda_toolkit"
    "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
end

function augment_platform!(platform::Platform)
    haskey(platform, "cuda") && return platform
    platform["cuda"] = cuda_toolkit_tag()
    return platform
end
