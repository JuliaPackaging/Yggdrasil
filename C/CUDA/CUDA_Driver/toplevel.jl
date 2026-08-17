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

using Base: thismajor, thisminor

# Precompile the process-spawning and version-parsing hot path of `inspect_driver`,
# because platform augmentation hooks call it from Pkg's `select_artifacts.jl`
# subprocess, which runs with `--compile=min`.
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
    # the helper executable is an artifact product, which does not exist on platforms
    # without a matching artifact (or before this module has been initialized).
    @isdefined(cuda_inspect_driver_path) || return nothing
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

"""
    get_driver_info()

Query the system CUDA driver, returning `nothing` on failure, or a tuple
`(driver_version, device_capabilities)`.

When called during precompilation (e.g. from a dependent JLL's platform augmentation
hook), the resolved driver path is registered as an include dependency, invalidating
the precompilation cache when the user upgrades their NVIDIA driver.
"""
function get_driver_info()
    # inspect the system driver (rather than `libcuda`, which may be the
    # forwards-compatible driver bundled in our artifact and which has private deps the
    # inspection subprocess wouldn't preload). only the system driver actually changes
    # when the user upgrades their NVIDIA driver, and it's the one we want to depend on
    # for cache invalidation.
    libcuda_system = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"

    info = inspect_driver(libcuda_system; inspect_devices=true)
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
