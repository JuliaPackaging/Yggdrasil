
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

libcuda_deps = [libcuda_debugger, libnvidia_nvvm, libnvidia_ptxjitcompiler, libnvidia_gpucomp, libnvidia_tileiras]
libcuda_system = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"

# if anything goes wrong, we'll use the system driver
global libcuda = libcuda_system

# check if we even have an artifact
if @isdefined(libcuda_compat)
    @debug "Forward-compatible driver found at $libcuda_compat"
else
    @debug "No forward-compatible driver available for your platform."
    return
end

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

# This shaves ~120ms off the load time
precompile(Base.cmd_gen, (Tuple{Tuple{Base.Cmd}, Tuple{String}, Tuple{Bool}, Tuple{Array{String, 1}}},))
precompile(Base.read, (Base.Cmd, Type{String}))

# helper function to load a driver, query its version, and optionally query device
# capabilities. needs to happen in a separate process because dlclose is unreliable.
function inspect_driver(driver, deps=String[]; inspect_devices=false)
    cmd = `$(cuda_inspect_driver()) $driver $inspect_devices $deps`

    # run the command
    version_strings = String[]
    try
        version_strings = split(read(cmd, String))
    catch _
        return nothing
    end

    # parse the versions
    driver_version = parse(VersionNumber, version_strings[1])
    if inspect_devices
        device_capabilities = map(str -> parse(VersionNumber, str), version_strings[2:end])
        return driver_version, device_capabilities
    else
        return driver_version
    end
end

# fetch driver details
compat_driver_task = @static if VERSION >= v"1.12-"
    # XXX: avoid concurrent compilation (JuliaLang/julia#59834)
    Threads.@spawn :samepool inspect_driver(libcuda_compat, libcuda_deps)
else
    Threads.@spawn inspect_driver(libcuda_compat, libcuda_deps)
end
system_driver_task = @static if VERSION >= v"1.12-"
    # XXX: avoid concurrent compilation (JuliaLang/julia#59834)
    Threads.@spawn :samepool inspect_driver(libcuda_system; inspect_devices=true)
else
    Threads.@spawn inspect_driver(libcuda_system; inspect_devices=true)
end
compat_driver_details = fetch(compat_driver_task)
if compat_driver_details === nothing
    @debug "Failed to load forwards-compatible driver."
    return
end
compat_driver_version = compat_driver_details::VersionNumber
@debug "Forwards compatible driver version: $compat_driver_version"
system_driver_details = fetch(system_driver_task)
if system_driver_details === nothing
    @debug "Failed to load system driver."
    return
end
system_driver_version = system_driver_details[1]::VersionNumber
device_capabilities = system_driver_details[2]::Vector{VersionNumber}
@debug "System driver version: $system_driver_version"

# determine if loading the forwards-compatible driver would exclude devices
for (dev, cap) in enumerate(device_capabilities)
    # CUDA 12 deprecated Kepler
    if compat_driver_version >= v"12" && system_driver_version < v"12" && v"3.0" <= cap <= v"3.5"
        @debug "Loading forwards-compatible driver would exclude device $dev with capability $cap"
        return
    end

    # CUDA 13 deprecated Maxwell, Pascal, and Volta
    if compat_driver_version >= v"13" && system_driver_version < v"13" && v"5.0" <= cap <= v"7.2"
        @debug "Loading forwards-compatible driver would exclude device $dev with capability $cap"
        return
    end
end

# finally, load the forwards-compatible driver
@debug "Using forwards-compatible CUDA driver."
global libcuda = libcuda_compat

# load the driver and its dependencies; this should now always succeed
# as we've already verified that we can load it in a separate process.
for dep in libcuda_deps
    Libdl.dlopen(dep; throw_error=true)
end
Libdl.dlopen(libcuda_compat; throw_error=true)
