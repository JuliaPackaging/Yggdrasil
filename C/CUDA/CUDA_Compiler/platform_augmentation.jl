using Base.BinaryPlatforms

using Libdl

# re-use the CUDA_Runtime_jll preference to select the appropriate compiler
const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)
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
const version_preference = parse_version_preference("version")

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

# returns the value for the "cuda" tag we should use in the platform ("$MAJOR")
# or nothing if no CUDA driver was found.
function cuda_driver_tag()
    if version_preference !== missing
        @debug "CUDA version override: $version_preference"
        "$(version_preference.major)"
    else
        cuda_driver = get_driver_version()
        if cuda_driver === nothing
            @debug "Failed to query CUDA driver version"
            return nothing
        end
        @debug "CUDA driver version: $cuda_driver"

        "$(cuda_driver.major)"
    end
end

function augment_platform!(platform::Platform)
    if !haskey(platform, "cuda")
        platform["cuda"] = something(cuda_driver_tag(), "none")
        # XXX: use "none" when we couldn't find a compatible toolkit.
        #      we can't just leave off the platform tag or Pkg would select *any* artifact.
    end

    return platform
end
