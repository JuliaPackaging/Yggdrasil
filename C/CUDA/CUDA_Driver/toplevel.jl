# The driver CUDA.jl and dependent JLLs should use: the system driver, unless `__init__`
# decides to use the bundled forwards-compatible one and replaces this. Defined here, in
# the JLL's `toplevel_block`, so that it exists on every platform -- also where no
# artifact matches and there is no `__init__` -- and consumers can rely on it.
global libcuda = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"

# `__init__` picks between the system driver and the bundled forwards-compatible one
# based on this preference, and dependent JLLs bake the resulting driver into the
# artifact they select. Base keys compile-time preferences by the recording module's own
# UUID, so they cannot register it themselves; recording it here invalidates our cache,
# and theirs along with it.
Base.record_compiletime_preference(Base.UUID("4ee394cb-3365-5eb0-8335-949819d2adfc"),
                                   "compat")

# inspect_driver(driver, deps=String[]; inspect_devices=false)
#
# Private helper for `__init__`: invoke the `cuda_inspect_driver` helper in a subprocess
# to query a CUDA driver without dlopen'ing it in this process, which matters because
# `__init__` compares two drivers and must not load the one it rejects. The helper
# verifies the driver actually works by calling `cuInit` (dlopen and
# `cuDriverGetVersion` succeed even on a driver that mismatches the loaded kernel-mode
# driver). Returns `nothing` on failure, logging the helper's diagnostic at debug level
# so that e.g. a driver failing `cuInit` can be told apart from one that failed to load;
# otherwise a NamedTuple `(; path, version, capabilities)` where `path` is the resolved
# absolute path to the driver, `version` is the driver's reported version, and
# `capabilities` is a `Vector{VersionNumber}` of device compute capabilities -- empty
# when `inspect_devices` is `false`.
function inspect_driver(driver, deps=String[]; inspect_devices::Bool=false)
    # the helper executable is an artifact product, which does not exist on platforms
    # without a matching artifact (or before this module has been initialized).
    @isdefined(cuda_inspect_driver_path) || return nothing
    cmd = `$cuda_inspect_driver_path $driver $inspect_devices $deps`
    out = IOBuffer()
    err = IOBuffer()
    proc = try
        run(pipeline(ignorestatus(cmd); stdout=out, stderr=err))
    catch _
        # spawn failure (e.g. missing or non-executable helper)
        @debug "Could not launch the driver inspection helper for $driver"
        return nothing
    end
    if !success(proc)
        reason = strip(String(take!(err)))
        @debug "Inspection of driver $driver failed" * (isempty(reason) ? "" : ": $reason")
        return nothing
    end
    lines = readlines(seekstart(out))
    if length(lines) < 2
        @debug "Inspection of driver $driver returned unexpected output"
        return nothing
    end
    path = lines[1]
    version = tryparse(VersionNumber, lines[2])
    if version === nothing
        @debug "Inspection of driver $driver reported an unparseable version: $(lines[2])"
        return nothing
    end
    capabilities = VersionNumber[]
    if inspect_devices
        for i in 3:length(lines)
            cap = tryparse(VersionNumber, lines[i])
            cap === nothing && continue
            push!(capabilities, cap)
        end
    end
    return (; path, version, capabilities)
end

# precompile the two calls `__init__` makes, plus the Base methods on their
# process-spawning path that are only reached through dynamic dispatch
precompile(inspect_driver, (String, Vector{String}))
precompile(Core.kwcall, (@NamedTuple{inspect_devices::Bool}, typeof(inspect_driver), String))
precompile(Tuple{typeof(Base.cmd_gen), Tuple{Tuple{Base.Cmd}, Tuple{String}, Tuple{Bool}, Tuple{Array{String, 1}}}})
precompile(Tuple{typeof(Base.arg_gen), Bool})
precompile(Tuple{typeof(Base.push!), Array{Base.VersionNumber, 1}, Base.VersionNumber})
