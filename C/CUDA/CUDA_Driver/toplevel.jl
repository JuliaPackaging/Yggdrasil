# Driver inspection and CUDA toolkit selection functionality, shared with other packages:
# the platform augmentation hooks of dependent JLLs (CUDA_Runtime_jll, CUDA_Compiler_jll)
# and CUDA.jl call into this module. This is why the code lives in the JLL's
# `toplevel_block` -- available on every platform, even when no artifact matches --
# rather than in its `init_block`, which only exists in per-platform wrappers.
#
# Consumers may be running against a stale version of this package, because platform
# augmentation hooks execute in an ill-defined environment where the manifest may be
# inconsistent (JuliaLang/Pkg.jl#3225). Changes here must therefore remain backwards
# compatible: don't change signatures or behavior without registering appropriate
# compat bounds in the consuming JLLs, and keep `selection_api` bumps in mind as a
# last-resort version marker for consumers to check.
const selection_api = v"1"

# `__init__` picks between the system driver and the bundled forwards-compatible one
# based on this preference, and `get_driver_info` reports whichever it picked, so
# dependent JLLs bake the preference into the artifact they select. Base keys
# compile-time preferences by the recording module's own UUID, so they cannot register
# it themselves; recording it here invalidates our cache, and theirs along with it.
Base.record_compiletime_preference(Base.UUID("4ee394cb-3365-5eb0-8335-949819d2adfc"),
                                   "compat")

using Base: thismajor, thisminor

"""
    is_tegra()

Return whether the host is an NVIDIA Tegra system. This definition is available
even when CUDA_Driver_jll has no matching artifact.
"""
is_tegra() = _is_tegra()

"""
    l4t_version()

Return the NVIDIA Linux for Tegra release as a `VersionNumber`, or `nothing` if
it is unavailable or cannot be parsed. Unlike CUDA_Driver_jll's private artifact
routing tag, this reports the complete release (for example, `v"35.6.5"`) without
clamping. This definition is available even when CUDA_Driver_jll has no matching
artifact.
"""
l4t_version() = _l4t_version()

# Precompile statements for the process-spawning and version-parsing hot path of
# `inspect_driver`, because platform augmentation hooks call it from Pkg's
# `select_artifacts.jl` subprocess, which runs with `--compile=min`. The entry
# points are precompiled at the bottom of this file (which caches their inferable
# callees as well); Base methods only reached through dynamic dispatch are listed
# here explicitly.
precompile(Tuple{typeof(Base.cmd_gen), Tuple{Tuple{Base.Cmd}, Tuple{String}, Tuple{Bool}, Tuple{Array{String, 1}}}})
precompile(Tuple{typeof(Base.arg_gen), Bool})
precompile(Tuple{typeof(Base.push!), Array{Base.VersionNumber, 1}, Base.VersionNumber})

"""
    inspect_driver(driver, deps=String[]; inspect_devices=false)

Invoke the `cuda_inspect_driver` helper in a subprocess to query a CUDA driver
without dlopen'ing it in the caller's process. The helper verifies the driver
actually works by calling `cuInit` (dlopen and `cuDriverGetVersion` succeed even
on a driver that mismatches the loaded kernel-mode driver). Returns `nothing` on
failure, logging the helper's diagnostic at debug level so that e.g. a driver
failing `cuInit` can be told apart from one that failed to load; otherwise a
NamedTuple `(; path, version, capabilities)` where `path` is the resolved
absolute path to the driver, `version` is the driver's reported version, and
`capabilities` is a `Vector{VersionNumber}` of device compute capabilities —
empty when `inspect_devices` is `false`.
"""
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

"""
    get_driver_info()

Query the CUDA driver, returning `nothing` on failure, or a tuple
`(driver_version, device_capabilities)`.

This inspects `libcuda`, i.e. whichever of the system driver and the bundled
forwards-compatible driver `__init__` settled on, so that the reported version is the
one code in this session will actually be running against.

When called during precompilation (e.g. from a dependent JLL's platform augmentation
hook), the resolved driver path is registered as an include dependency, invalidating
the precompilation cache when the user upgrades their NVIDIA driver.
"""
function get_driver_info()
    # `libcuda` is set by `__init__`, so it does not exist on platforms without a
    # matching artifact (where there is no driver to speak of anyway).
    @isdefined(libcuda) || return nothing

    # the forwards-compatible driver has private dependencies that the inspection
    # subprocess has to preload; `__init__` collected them while probing it.
    deps = if @isdefined(libcuda_compat) && libcuda == libcuda_compat
        libcuda_deps
    else
        String[]
    end

    info = inspect_driver(libcuda, deps; inspect_devices=true)
    info === nothing && return nothing

    @debug "Adding include dependency on $(info.path)"
    Base.include_dependency(info.path)

    return (info.version, info.capabilities)
end

# CUDA toolkit support for each GPU compute capability. Maps a compute
# capability to a `(lo, hi)` tuple of inclusive toolkit version bounds:
# `lo` is the toolkit that introduced support for the architecture, `hi` is
# the last toolkit that still supports it (toolkits drop architecture support
# over time). `v"99"` is used as an open-ended upper bound for capabilities
# still supported by current toolkits.
#
# Keep in sync with `ptxas_cap_db` in CUDACore/src/compatibility.jl, where these bounds
# are measured (by pinning `CUDA_SDK_jll` to each release and reading the `--gpu-name`
# list off that toolkit's ptxas) rather than inferred.
const cuda_cap_db = Dict{VersionNumber, NTuple{2, VersionNumber}}(
    v"1.0"   => (v"0",     v"6.5"),
    v"1.1"   => (v"0",     v"6.5"),
    v"1.2"   => (v"0",     v"6.5"),
    v"1.3"   => (v"0",     v"6.5"),
    v"2.0"   => (v"0",     v"8.0"),
    v"2.1"   => (v"0",     v"8.0"),
    v"3.0"   => (v"4.2",   v"10.2"),
    v"3.2"   => (v"6.0",   v"10.2"),
    v"3.5"   => (v"5.0",   v"11.8"),
    v"3.7"   => (v"6.5",   v"11.8"),
    v"5.0"   => (v"6.0",   v"12.9"),
    v"5.2"   => (v"7.0",   v"12.9"),
    v"5.3"   => (v"7.5",   v"12.9"),
    v"6.0"   => (v"8.0",   v"12.9"),
    v"6.1"   => (v"8.0",   v"12.9"),
    v"6.2"   => (v"8.0",   v"12.9"),
    v"7.0"   => (v"9.0",   v"12.9"),
    v"7.2"   => (v"9.2",   v"12.9"),
    v"7.5"   => (v"10.0",  v"99"),
    v"8.0"   => (v"11.0",  v"99"),
    v"8.6"   => (v"11.1",  v"99"),
    v"8.7"   => (v"11.4",  v"99"),
    v"8.8"   => (v"13.0",  v"99"),
    v"8.9"   => (v"11.8",  v"99"),
    v"9.0"   => (v"11.8",  v"99"),
    v"10.0"  => (v"12.8",  v"99"),
    v"10.1"  => (v"12.8",  v"12.9"),
    v"10.3"  => (v"12.9",  v"99"),
    v"10.7"  => (v"13.4",  v"99"),
    v"11.0"  => (v"13.0",  v"99"),
    v"12.0"  => (v"12.8",  v"99"),
    v"12.1"  => (v"12.9",  v"99"),
)

"""
    supported_capabilities(toolkit::VersionNumber) -> Set{VersionNumber}

Return the set of GPU compute capabilities supported by the given CUDA toolkit.
Comparisons are at minor-version granularity, so e.g. `v"12.9.1"` and `v"12.9.0"`
are treated identically.
"""
function supported_capabilities(toolkit::VersionNumber)
    minor = thisminor(toolkit)
    Set(cap for (cap, (lo, hi)) in cuda_cap_db if lo <= minor <= hi)
end

"""
    select_cuda_toolkit(toolkits, prerelease_toolkits) -> Union{Nothing,VersionNumber}

Select the best CUDA toolkit from `toolkits` (an ascending list of candidate versions)
for the system driver and its devices, or `nothing` if the driver cannot be queried or
no candidate is compatible. Toolkits listed in `prerelease_toolkits` are never selected
automatically.

The candidate lists are taken as arguments -- rather than baked into this package -- so
that they always come from the (possibly newer) consuming JLL doing the selection.
"""
function select_cuda_toolkit(toolkits::Vector{VersionNumber},
                             prerelease_toolkits::Vector{VersionNumber})
    driver_info = get_driver_info()
    if driver_info === nothing
        @debug "Failed to query the CUDA driver and its devices"
        return nothing
    end
    cuda_driver_version, device_capabilities = driver_info
    @debug "CUDA driver version: $cuda_driver_version"
    if isempty(device_capabilities)
        @debug "No CUDA devices visible"
    else
        @debug "CUDA device compute capabilities: $(join(device_capabilities, ", "))"
    end

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    compatible_toolkits = filter(toolkits) do toolkit
        # never auto-select an EA/preview toolkit; those have to be requested explicitly
        # through the "version" preference.
        toolkit in prerelease_toolkits && return false

        # enhanced compatibility
        #
        # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
        #  from within a CUDA major release family can run, with limited feature-set,
        #  on systems having at least the minimum required driver version"
        if cuda_driver_version >= v"11"
            thismajor(toolkit) <= thismajor(cuda_driver_version)
        else
            thisminor(toolkit) <= thisminor(cuda_driver_version)
        end
    end
    if isempty(compatible_toolkits)
        @error "CUDA driver $(cuda_driver_version) is not compatible with any supported CUDA toolkit ($(join(toolkits, ", ", " or ")))"
        return nothing
    end

    # narrow the candidate toolkits to those that support the user's hardware,
    # giving priority to the newest devices: walk device capabilities from
    # newest to oldest, intersecting the candidate set with toolkits supporting
    # each. if an older device cannot be supported alongside newer ones, drop
    # it rather than discard the whole selection, as the user almost certainly
    # cares more about their newest hardware working than their oldest.
    if !isempty(device_capabilities)
        supports_capability(toolkit, cap) = let minor = thisminor(toolkit)
            # capabilities absent from `cuda_cap_db` are presumed unsupported:
            # they're either future architectures that need a newer toolkit
            # than anything we know about, or fictional. either way no toolkit
            # in our list is known to handle them.
            haskey(cuda_cap_db, cap) || return false
            lo, hi = cuda_cap_db[cap]
            lo <= minor <= hi
        end
        for cap in sort(unique(device_capabilities); rev=true)
            subset = filter(t -> supports_capability(t, cap), compatible_toolkits)
            if isempty(subset)
                @debug "No remaining toolkit supports device with compute capability $cap; dropping it from the selection"
            else
                compatible_toolkits = subset
            end
        end
    end

    cuda_toolkit = thisminor(last(compatible_toolkits))
    @debug "Selected CUDA toolkit: $cuda_toolkit"
    return cuda_toolkit
end

# precompile the entry points used by platform augmentation hooks (see above)
precompile(inspect_driver, (String,))
precompile(inspect_driver, (String, Vector{String}))
precompile(Core.kwcall, (@NamedTuple{inspect_devices::Bool}, typeof(inspect_driver), String))
precompile(get_driver_info, ())
precompile(select_cuda_toolkit, (Vector{VersionNumber}, Vector{VersionNumber}))
