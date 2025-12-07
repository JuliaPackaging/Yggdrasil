
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

# helper function to load a driver, query its version, and optionally query device
# capabilities. needs to happen in a separate process because dlclose is unreliable.
function inspect_driver(driver, deps=String[]; inspect_devices=false)
    script = raw"""
        using Libdl

        const DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR = 75
        const DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR = 76

        function main(driver, inspect_devices, deps...)
            inspect_devices = parse(Bool, inspect_devices)

            for dep in deps
                Libdl.dlopen(dep; throw_error=false) === nothing && exit(-1)
            end

            library_handle = Libdl.dlopen(driver; throw_error=false)
            library_handle === nothing && return -1

            cuInit = Libdl.dlsym(library_handle, "cuInit")
            status = ccall(cuInit, Cint, (UInt32,), 0)
            status == 0 || return -2

            cuDriverGetVersion = Libdl.dlsym(library_handle, "cuDriverGetVersion")
            version = Ref{Cint}()
            status = ccall(cuDriverGetVersion, Cint, (Ptr{Cint},), version)
            status == 0 || return -3
            major, ver = divrem(version[], 1000)
            minor, patch = divrem(ver, 10)
            println(major, ".", minor, ".", patch)

            if inspect_devices
                cuDeviceGetCount = Libdl.dlsym(library_handle, "cuDeviceGetCount")
                device_count = Ref{Cint}()
                status = ccall(cuDeviceGetCount, Cint, (Ptr{Cint},), device_count)
                status == 0 || return -4

                cuDeviceGet = Libdl.dlsym(library_handle, "cuDeviceGet")
                cuDeviceGetAttribute = Libdl.dlsym(library_handle, "cuDeviceGetAttribute")
                for i in 1:device_count[]
                    device = Ref{Cint}()
                    status = ccall(cuDeviceGet, Cint, (Ptr{Cint}, Cint), device, i-1)
                    status == 0 || return -5

                    major = Ref{Cint}()
                    status = ccall(cuDeviceGetAttribute, Cint, (Ptr{Cint}, UInt32, Cint), major, DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR, device[])
                    status == 0 || return -6
                    minor = Ref{Cint}()
                    status = ccall(cuDeviceGetAttribute, Cint, (Ptr{Cint}, UInt32, Cint), minor, DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR, device[])
                    status == 0 || return -7
                    println(major[], ".", minor[])
                end
            end

            return 0
        end

        exit(main(ARGS...))
    """

    # make sure we don't include any system image flags here since this will cause an infinite loop of __init__()
    cmd = ```$(Cmd(filter(!startswith(r"-J|--sysimage"), Base.julia_cmd().exec)))
             -O0 --compile=min -t1 --startup-file=no
             -e $script $driver $inspect_devices $deps```

    # make sure we use a fresh environment we can load Libdl in
    cmd = addenv(cmd, "JULIA_LOAD_PATH" => nothing, "JULIA_DEPOT_PATH" => nothing)

    # run the command
    out = Pipe()
    proc = run(pipeline(cmd, stdin=devnull, stdout=out), wait=false)
    close(out.in)
    out_reader = @static if VERSION >= v"1.12-"
        # XXX: avoid concurrent compilation (JuliaLang/julia#59834)
        Threads.@spawn :samepool String.(readlines(out))
    else
        Threads.@spawn String.(readlines(out))
    end
    wait(proc)
    success(proc) || return nothing

    # parse the versions
    version_strings = fetch(out_reader)
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
