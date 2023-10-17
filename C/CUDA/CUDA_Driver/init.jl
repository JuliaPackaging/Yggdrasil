# global variables we will set
global libcuda = nothing
global libcuda_version = nothing
global libcuda_original_version = nothing
# compat_version is set in build_tarballs.jl

# manual use of preferences, as we can't depend on additional packages in JLLs.
CUDA_Driver_jll_uuid = Base.UUID("4ee394cb-3365-5eb0-8335-949819d2adfc")
preferences = Base.get_preferences(CUDA_Driver_jll_uuid)
function parse_preference(val)
    if isa(val, Bool)
        val
    elseif isa(val, String)
        parsed = tryparse(Bool, val)
        if parsed === nothing
            @error "CUDA compat preference is not valid; expected a boolean, but got '$val'"
            missing
        else
            parsed
        end
    else
        @error "CUDA compat preference is not valid; expected a boolean, but got '$val'"
        missing
    end
end
compat_preference = if haskey(preferences, "compat")
    parse_preference(preferences["compat"])
elseif haskey(ENV, "JULIA_CUDA_USE_COMPAT")
    parse_preference(ENV["JULIA_CUDA_USE_COMPAT"])
else
    missing
end

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
function init_driver(library_handle)
    function_handle = Libdl.dlsym(library_handle, "cuInit")
    status = ccall(function_handle, Cint, (UInt32,), 0)
    # libcuda.cuInit dlopens NULL, aka. the main program, which increments the refcount
    # of libcuda. this breaks future dlclose calls, so eagerly lower the refcount already.
    Libdl.dlclose(library_handle)
    return status
end

# find the system driver
system_driver = if Sys.iswindows()
    Libdl.find_library("nvcuda")
else
    Libdl.find_library(["libcuda.so.1", "libcuda.so"])
end
if system_driver == ""
    @debug "No system CUDA driver found"
    return
end
libcuda = system_driver

# check if the system driver is already loaded. in that case, we have to use it because
# the code that loaded it in the first place might have made assumptions based on it.
system_driver_loaded = Libdl.dlopen(system_driver, Libdl.RTLD_NOLOAD;
                                    throw_error=false) !== nothing
driver_handle = Libdl.dlopen(system_driver; throw_error=false)
if driver_handle === nothing
    @debug "Failed to load system CUDA driver"
    return
end

# query the system driver version
# XXX: apparently cuDriverGetVersion can be used before cuInit,
#      despite the docs stating "any function [...] will return
#      CUDA_ERROR_NOT_INITIALIZED"; is this a recent change?
system_version = driver_version(driver_handle)
if system_version === nothing
    @debug "Failed to query system CUDA driver version"
    # note that libcuda is already set here, so we'll continue using the system driver
    # and CUDA.jl will likely report the reason cuDriverGetVersion didn't work.
    return
end
@debug "System CUDA driver found at $system_driver, detected as version $system_version"
libcuda = system_driver
libcuda_version = system_version

# check if the system driver is already loaded (see above)
if system_driver_loaded
    @debug "System CUDA driver already loaded, continuing using it"
    return
end

# check the user preference
if compat_preference !== missing
    @debug "CUDA compat preference: $(compat_preference)"
    if !compat_preference
        @debug "User disallows using forward-compatible driver."
        return
    end
end

# check the version
if system_version >= compat_version
    @debug "System CUDA driver is recent enough; not using forward-compatible driver"
    return
end

# check if we can unload the system driver.
# if we didn't, we can't consider a forward compatible library because that would
# risk having multiple copies of libcuda.so loaded (also see NVIDIA bug #3418723)
Libdl.dlclose(driver_handle)
system_driver_loaded = Libdl.dlopen(system_driver, Libdl.RTLD_NOLOAD;
                                    throw_error=false) !== nothing
if system_driver_loaded
    @debug "Could not unload the system CUDA library;" *
           " this prevents use of the forward-compatible driver"
    return
end

# check if this process is hooked by CUDA's injection libraries, which prevents
# unloading libcuda after dlopening. this is problematic, because we might want to
# after loading a forwards-compatible libcuda and realizing we can't use it. without
# being able to unload the library, we'd run into issues (see NVIDIA bug #3418723)
hooked = haskey(ENV, "CUDA_INJECTION64_PATH")
if hooked
    @debug "Running under CUDA injection tools;" *
            " this prevents use of the forward-compatible driver"
    return
end

# check if we even have an artifact
if !@isdefined(libcuda_compat)
    @debug "No forward-compatible CUDA library available for your platform."
    return
end
compat_driver = libcuda_compat
@debug "Forward-compatible CUDA driver found at $compat_driver;" *
       " known to be version $(compat_version)"

# finally, load the compatibility driver to see if it supports this platform
driver_handle = Libdl.dlopen(compat_driver; throw_error=true)

init_status = init_driver(driver_handle)
if init_status != 0
    @debug "Could not use forward compatibility package (error $init_status)"

    # see comment above about unloading the system driver
    Libdl.dlclose(driver_handle)
    compat_driver_loaded = Libdl.dlopen(compat_driver, Libdl.RTLD_NOLOAD;
                                        throw_error=false) !== nothing
    if compat_driver_loaded
        error("Could not unload forwards compatible CUDA driver." *
              "This is probably caused by running Julia under a tool that hooks CUDA API calls." *
              "In that case, prevent Julia from loading multiple drivers" *
              " by setting JULIA_CUDA_USE_COMPAT=false in your environment.")
    end

    return
end

# load dependent libraries
# XXX: we can do this after loading libcuda, because these are runtime dependencies.
#      if loading libcuda or calling cuInit would already require these, do so earlier.
Libdl.dlopen(libcuda_debugger; throw_error=true)
Libdl.dlopen(libnvidia_nvvm; throw_error=true)
Libdl.dlopen(libnvidia_ptxjitcompiler; throw_error=true)

@debug "Successfully loaded forwards-compatible CUDA driver"
libcuda = compat_driver
libcuda_version = compat_version
libcuda_original_version = system_version
