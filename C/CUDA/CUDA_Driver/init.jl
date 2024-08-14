# global variables we will set
global libcuda = nothing

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

# find and select the system driver
libcuda_system = if Sys.iswindows()
    Libdl.find_library("nvcuda")
else
    Libdl.find_library(["libcuda.so.1", "libcuda.so"])
end
if libcuda_system == ""
    @debug "No system driver found"
    return
end
@debug "System driver found at $libcuda_system"
libcuda = libcuda_system

# check if we even have an artifact
if !@isdefined(libcuda_compat)
    @debug "No forward-compatible driver available for your platform."
    return
end
@debug "Forward-compatible driver found at $libcuda_compat"

# check the user preference
if compat_preference !== missing
    if !compat_preference
        @debug "User disallows using forward-compatible driver."
        return
    end
end

# check if the system driver is already loaded. in that case, we have to use it because
# the code that loaded it in the first place might have made assumptions based on it.
if Libdl.dlopen(libcuda_system, Libdl.RTLD_NOLOAD; throw_error=false) !== nothing
    @debug "System CUDA driver already loaded, continuing using it."
    return
end

# try to load the forward-compatible driver in a separate process
function try_driver(driver, deps)
    script = raw"""
        using Libdl
        driver, deps... = ARGS

        for dep in deps
            Libdl.dlopen(dep; throw_error=false) === nothing && exit(-1)
        end

        library_handle = Libdl.dlopen(driver; throw_error=false)
        library_handle === nothing && exit(-1)

        function_handle = Libdl.dlsym(library_handle, "cuInit")
        status = ccall(function_handle, Cint, (UInt32,), 0)
        status == 0 || exit(-2)

        exit(0)
    """
    success(`$(Base.julia_cmd()) --compile=min -t1 --startup-file=no -e $script $driver $deps`)
end
libcuda_deps = [libcuda_debugger, libnvidia_nvvm, libnvidia_ptxjitcompiler]
if !try_driver(libcuda_compat, libcuda_deps)
    @debug "Failed to load forwards-compatible driver."
    return
end

@debug "Successfully loaded forwards-compatible CUDA driver."
libcuda = libcuda_compat

# load driver dependencies
for dep in libcuda_deps
    Libdl.dlopen(dep; throw_error=true)
end
# XXX: should we also load the driver here?
