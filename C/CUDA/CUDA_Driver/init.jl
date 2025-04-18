
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

libcuda_deps = [libcuda_debugger, libnvidia_nvvm, libnvidia_ptxjitcompiler]
libcuda_system = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"
can_use_compat = true

# check if we even have an artifact
if @isdefined(libcuda_compat)
    @debug "Forward-compatible driver found at $libcuda_compat"
else
    @debug "No forward-compatible driver available for your platform."
    can_use_compat = false
end

# check the user preference
if compat_preference !== missing
    if !compat_preference
        @debug "User disallows using forward-compatible driver."
        can_use_compat = false
    end
end

# check if the system driver is already loaded. in that case, we have to use it because
# the code that loaded it in the first place might have made assumptions based on it.
if Libdl.dlopen(libcuda_system, Libdl.RTLD_NOLOAD; throw_error=false) !== nothing
    @debug "System CUDA driver already loaded, continuing using it."
    can_use_compat = false
end

# check if we can load the forward-compatible driver in a separate process
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

    # make sure we don't include any system image flags here since this will cause an infinite loop of __init__()
    cmd = ```$(Cmd(filter(!startswith(r"-J|--sysimage"), Base.julia_cmd().exec)))
             --compile=min -t1 --startup-file=no
             -e $script $driver $deps```
    proc = withenv("JULIA_LOAD_PATH"=> nothing, "JULIA_DEPOT_PATH"=> nothing) do
        # make sure we use a fresh environment we can load Libdl in
        run(ignorestatus(cmd))
    end
    success(proc)
end

if can_use_compat && !try_driver(libcuda_compat, libcuda_deps)
    @debug "Failed to load forwards-compatible driver."
    can_use_compat = false
end

# finally, load the appropriate driver
if can_use_compat
    @debug "Using forwards-compatible CUDA driver."
    global libcuda = libcuda_compat

    # load the driver and its dependencies; this should now always succeed
    # as we've already verified that we can load it in a separate process.
    for dep in libcuda_deps
        Libdl.dlopen(dep; throw_error=true)
    end
    Libdl.dlopen(libcuda_compat; throw_error=true)
elseif Libdl.dlopen(libcuda_system; throw_error=false) !== nothing
    @debug "Using system CUDA driver."
    global libcuda = libcuda_system
else
    @debug "Could not load system CUDA driver."
    global libcuda = nothing
end
