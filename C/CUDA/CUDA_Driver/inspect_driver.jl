# Precompile the process-spawning and version-parsing hot path of `inspect_driver`,
# because platform augmentation runs under Pkg's `select_artifacts.jl` subprocess
# with `--compile=min`, where non-precompiled methods are interpreted (and slow).
precompile(Tuple{typeof(Base.cmd_gen), Tuple{Tuple{Base.Cmd}, Tuple{String}, Tuple{Bool}, Tuple{Array{String, 1}}}})
precompile(Tuple{typeof(Base.arg_gen), Bool})
precompile(Tuple{typeof(Base.read), Base.Cmd, Type{String}})
precompile(Tuple{typeof(Base.readlines), Base.IOBuffer})
precompile(Tuple{typeof(Base.push!), Array{Base.VersionNumber, 1}, Base.VersionNumber})
precompile(Tuple{typeof(Base.Iterators.enumerate), Array{Base.VersionNumber, 1}})
precompile(Tuple{typeof(Base.iterate), Base.Iterators.Enumerate{Array{Base.VersionNumber, 1}}})
precompile(Tuple{typeof(Base.iterate), Base.Iterators.Enumerate{Array{Base.VersionNumber, 1}}, Tuple{Int64, Int64}})
precompile(Tuple{typeof(Base.indexed_iterate), Tuple{Int64, Base.VersionNumber}, Int64})
precompile(Tuple{typeof(Base.indexed_iterate), Tuple{Int64, Base.VersionNumber}, Int64, Int64})

"""
    inspect_driver(driver, deps=String[]; inspect_devices=false)

Invoke the `cuda_inspect_driver` helper in a subprocess to query a CUDA driver
without dlopen'ing it in the caller's process. Returns `nothing` on failure,
otherwise a NamedTuple `(; path, version, capabilities)` where `path` is the
resolved absolute path to the driver, `version` is the driver's reported
version, and `capabilities` is a `Vector{VersionNumber}` of device compute
capabilities — empty when `inspect_devices` is `false`.
"""
function inspect_driver(driver, deps=String[]; inspect_devices::Bool=false)
    cmd = `$cuda_inspect_driver_path $driver $inspect_devices $deps`
    output = try
        read(cmd, String)
    catch _
        return nothing
    end
    lines = readlines(IOBuffer(output))
    length(lines) < 2 && return nothing
    path = lines[1]
    version = tryparse(VersionNumber, lines[2])
    version === nothing && return nothing
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
