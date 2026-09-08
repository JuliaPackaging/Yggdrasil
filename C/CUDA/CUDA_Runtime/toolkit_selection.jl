# CUDA toolkit selection logic, shared between the platform augmentation blocks of
# CUDA_Runtime_jll and CUDA_Compiler_jll. The including build recipe must prepend a
# `CUDA_jll_uuids` list (preference namespaces, in decreasing order of priority),
# append `cuda_toolkits` and `cuda_prerelease_toolkits`, and append an
# `augment_platform!` implementation.
#
# This code is self-contained: it needs nothing from CUDA_Driver_jll except the name of
# the driver that package decided to load (`CUDA_Driver_jll.libcuda`), and falls back to
# the system driver when even that is unavailable (which can happen during initial
# installation, cf. JuliaLang/Pkg.jl#3225). The driver is queried in-process: this hook
# runs in throwaway processes (Pkg's artifact-selection subprocess, or the JLL's
# precompilation process) that have already loaded the chosen driver, so there is no
# reason to inspect it from a helper process like CUDA_Driver_jll's `__init__` does.

using Base.BinaryPlatforms

using Base: thismajor, thisminor

using Libdl

# read the preferences from the first UUID that has any CUDA selection preference set;
# namespaces are not merged, to avoid mixing related preferences from different sources.
# all namespaces are recorded regardless, so the precompilation cache is invalidated
# when a higher-priority namespace gains a preference later.
#
# we can't use Preferences.jl here, for the same manifest-related reasons we can't
# rely on CUDA_Driver_jll (see above).
const preferences = let
    selected = nothing
    for uuid in CUDA_jll_uuids
        Base.record_compiletime_preference(uuid, "version")
        Base.record_compiletime_preference(uuid, "local")
        prefs = Base.get_preferences(uuid)
        if selected === nothing &&
           any(key -> haskey(prefs, key), ["version", "local", "actual_version"])
            selected = prefs
        end
    end
    something(selected, Dict{String,Any}())
end

const local_preference = if haskey(preferences, "local")
    if isa(preferences["local"], Bool)
        preferences["local"]
    elseif isa(preferences["local"], String)
        use_local = tryparse(Bool, preferences["local"])
        if use_local === nothing
            @error "CUDA local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
            missing
        else
            use_local
        end
    else
        @error "CUDA local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
        missing
    end
elseif haskey(preferences, "version") && preferences["version"] == "local"
    # legacy support for CUDA.jl's old "version" preference format.
    # in this case, an "actual_version" preference is required.
    @debug "The version=local preference is deprecated, please use local=true instead."
    # XXX: turn this into a warning after HPC people have had the time to upgrade.
    true
else
    missing
end

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
const version_preference = if haskey(preferences, "version") && preferences["version"] == "local"
    # legacy support for CUDA.jl's old "version" preference format.
    # in this case, an "actual_version" preference is required.
    parse_version_preference("actual_version")
else
    parse_version_preference("version")
end

# platform augmentation hooks run in an ill-defined environment, where:
# - CUDA_Driver_jll may not be available
# - the wrong version of CUDA_Driver_jll may be available
#
# because of that, we need to be very careful about using that dependency: guard the
# import, and only ever read `libcuda` from it (defined on every platform since 13.3.4),
# falling back to the system driver when that is not possible.
#
# ref: https://github.com/JuliaLang/Pkg.jl/issues/3225
try
    using CUDA_Driver_jll
catch err
    # handled in get_driver_info below
end

# get the version of the local CUDA toolkit by querying the system libcudart
function get_runtime_version()
    cuda_runtime = if Sys.iswindows()
        Libdl.find_library(["cudart64_12", "cudart64_110"])
    else
        Libdl.find_library(["libcudart.so", "libcudart.so.12", "libcudart.so.11.0"])
    end
    if cuda_runtime == ""
        # no runtime library found
        @debug "No system CUDA runtime library found"
        return nothing
    end
    @debug "Found CUDA runtime library at '$cuda_runtime'"

    # minimal API call wrappers we need
    function cudaRuntimeGetVersion(library_handle)
        function_handle = Libdl.dlsym(library_handle, "cudaRuntimeGetVersion"; throw_error=false)
        if function_handle === nothing
            @debug "Runtime library seems invalid (does not contain 'cudaRuntimeGetVersion')"
            return nothing
        end
        version_ref = Ref{Cint}()
        status = ccall(function_handle, Cint, (Ptr{Cint},), version_ref)
        if status != 0
            @debug "Call to 'cudaRuntimeGetVersion' failed with status $status"
            return nothing
        end
        major, ver = divrem(version_ref[], 1000)
        minor, patch = divrem(ver, 10)
        return VersionNumber(major, minor, patch)
    end

    runtime_handle = Libdl.dlopen(cuda_runtime; throw_error=false)
    if runtime_handle === nothing
        @debug "Failed to load CUDA runtime library"
        return nothing
    end

    cudaRuntimeGetVersion(runtime_handle)
end

# query the CUDA driver, returning `nothing` on failure, or a tuple
# `(driver_version, device_capabilities)`.
#
# this inspects `CUDA_Driver_jll.libcuda`, i.e. whichever of the system driver and the
# bundled forwards-compatible driver its `__init__` settled on, so that the toolkit we
# select is sized for the driver code in this session will actually run against. when
# CUDA_Driver_jll cannot be loaded, we look at the system driver instead.
#
# when called during precompilation (i.e., from the JLL's own precompilation process),
# the resolved driver path is registered as an include dependency, invalidating the
# precompilation cache when the user upgrades their NVIDIA driver.
function get_driver_info()
    system_driver = Sys.iswindows() ? "nvcuda" : "libcuda.so.1"
    libcuda = if @isdefined(CUDA_Driver_jll) && isdefined(CUDA_Driver_jll, :libcuda)
        CUDA_Driver_jll.libcuda
    else
        @debug "CUDA_Driver_jll is not available; inspecting the system driver"
        system_driver
    end

    driver_handle = Libdl.dlopen(libcuda; throw_error=false)
    if driver_handle === nothing
        @debug "Failed to load CUDA driver $libcuda"
        return nothing
    end

    # minimal API call wrappers we need
    function lookup(name)
        function_handle = Libdl.dlsym(driver_handle, name; throw_error=false)
        if function_handle === nothing
            @debug "Driver library seems invalid (does not contain '$name')"
        end
        return function_handle
    end
    version_fn = lookup("cuDriverGetVersion")
    version_fn === nothing && return nothing
    version_ref = Ref{Cint}()
    status = ccall(version_fn, Cint, (Ptr{Cint},), version_ref)
    if status != 0
        @debug "Call to 'cuDriverGetVersion' failed with status $status"
        return nothing
    end
    major, ver = divrem(version_ref[], 1000)
    minor, patch = divrem(ver, 10)
    version = VersionNumber(major, minor, patch)

    # the device capabilities let us narrow the selection down to toolkits that support
    # the user's hardware, but they are only a refinement: the driver version alone
    # already determines a usable toolkit. so when `cuInit` fails -- no device visible
    # (CUDA_ERROR_NO_DEVICE, 100), the kernel-mode driver not loaded or mismatching the
    # library after an upgrade without a reboot (803), a driver too old for its own
    # library, ... -- we still select on the version: the resulting installation is
    # correct as soon as the system is fixed, whereas baking `none` into the selection
    # would leave the user without a toolkit until something re-triggers it.
    init_fn = lookup("cuInit")
    init_fn === nothing && return nothing
    capabilities = VersionNumber[]
    status = ccall(init_fn, Cint, (Cuint,), 0)
    if status == 100
        @debug "Call to 'cuInit' reported no CUDA-capable device; selecting on the driver version alone"
    elseif status != 0
        @debug "Call to 'cuInit' failed with status $status; selecting on the driver version alone"
    else
        count_fn = lookup("cuDeviceGetCount")
        get_fn = lookup("cuDeviceGet")
        attr_fn = lookup("cuDeviceGetAttribute")
        (count_fn === nothing || get_fn === nothing || attr_fn === nothing) && return (version, capabilities)
        count_ref = Ref{Cint}()
        status = ccall(count_fn, Cint, (Ptr{Cint},), count_ref)
        if status != 0
            @debug "Call to 'cuDeviceGetCount' failed with status $status; selecting on the driver version alone"
            count_ref[] = 0
        end
        for i in 0:count_ref[]-1
            dev_ref = Ref{Cint}()
            status = ccall(get_fn, Cint, (Ptr{Cint}, Cint), dev_ref, i)
            if status != 0
                @debug "Call to 'cuDeviceGet' failed with status $status; ignoring device $i"
                continue
            end
            major_ref = Ref{Cint}()
            minor_ref = Ref{Cint}()
            # CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR = 75, ..._MINOR = 76
            status = ccall(attr_fn, Cint, (Ptr{Cint}, Cint, Cint), major_ref, 75, dev_ref[])
            if status == 0
                status = ccall(attr_fn, Cint, (Ptr{Cint}, Cint, Cint), minor_ref, 76, dev_ref[])
            end
            if status != 0
                @debug "Call to 'cuDeviceGetAttribute' failed with status $status; ignoring device $i"
                continue
            end
            push!(capabilities, VersionNumber(major_ref[], minor_ref[]))
        end
    end

    # invalidate the precompilation cache when the driver changes.
    #
    # NOTE: when CUDA_Driver_jll adopted the bundled forwards-compatible driver, this only
    # covers that driver; the system driver, on which CUDA_Driver_jll's decision depends,
    # cannot be located from here (it shares its SONAME with the loaded compat driver, so
    # dlopen'ing it by name just returns the latter). A system driver upgrade then does
    # not invalidate the baked selection; the `compat` preference recorded by
    # CUDA_Driver_jll does at least cover the user changing their mind.
    driver_path = Libdl.dlpath(driver_handle)
    @debug "Adding include dependency on $driver_path"
    Base.include_dependency(driver_path)

    return (version, capabilities)
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

# Jetson library ceilings. NVIDIA builds the Tegra (`linux-aarch64`) redistributables for
# the JetPack generation they belong to: from CUDA 12.6 on, the Jetson cuBLAS binaries
# only carry SASS for sm_87 (Orin) and newer, dropping Xavier (sm_7.2) even though the
# toolkit's ptxas still targets it (`cuda_cap_db` says 12.9). Code CUDA.jl compiles itself
# keeps working, but every vendor library fails with CUBLAS_STATUS_ARCH_MISMATCH or a
# launch failure. So on Tegra hosts, a device additionally bounds the selection by the
# newest Jetson redistributable that still ships its SASS. Measured with
# `cuobjdump --list-elf` on the Jetson artifacts of CUDA_Runtime_jll.
const jetson_cap_db = Dict{VersionNumber, NTuple{2, VersionNumber}}(
    v"7.2"   => (v"9.2",   v"12.5"),
)

# select the best CUDA toolkit from `toolkits` (an ascending list of candidate versions)
# for the driver and its devices, or `nothing` if the driver cannot be queried or no
# candidate is compatible. Toolkits listed in `prerelease_toolkits` are never selected
# automatically.
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
            if is_tegra() && haskey(jetson_cap_db, cap)
                lo, hi = jetson_cap_db[cap]
            end
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

# returns the value for the "cuda" tag we should use in the platform ("$MAJOR.$MINOR")
# or nothing if no compatible CUDA toolkit was found.
function cuda_toolkit_tag()
    # check if the user requested a specific version
    if version_preference !== missing
        @debug "CUDA version override: $version_preference"
        cuda_version_override = version_preference
    end

    # check if the user requested to use a local version
    if local_preference !== missing
        @debug "CUDA local preference: $(local_preference)"
        if local_preference && !@isdefined(cuda_version_override)
            # the user didn't specify a version, so try quering it
            version = get_runtime_version()
            if version === nothing
                @error """Local CUDA version requested, but could not query the runtime version.
                          Either make sure CUDA is available, or set the CUDA version explicitly."""
                return nothing
            end
            @debug "Local CUDA runtime version: $version"
            cuda_version_override = version
        end

        # if we're using a local toolkit, use the version as-is. this may result in an
        # incompatible toolkit being used, but CUDA.jl will complain about that.
        if local_preference
            return "$(cuda_version_override.major).$(cuda_version_override.minor)"
        end
    end

    # with a version override, we don't need to (and shouldn't) inspect the driver:
    # this supports precompiling with a fixed version without a driver available.
    if @isdefined(cuda_version_override)
        compatible_toolkits =
            filter(toolkit -> thisminor(toolkit) == thisminor(cuda_version_override),
                   cuda_toolkits)
        if isempty(compatible_toolkits)
            @error "Requested CUDA version $(cuda_version_override) does not match any supported CUDA toolkit ($(join(cuda_toolkits, ", ", " or ")))"
            return nothing
        end
        cuda_toolkit = thisminor(last(compatible_toolkits))
        @debug "Selected CUDA toolkit: $cuda_toolkit"
        return "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
    end

    # otherwise, inspect the driver to determine its version and the compute capability
    # of each visible device, and pick the newest toolkit that fits.
    cuda_toolkit = try
        select_cuda_toolkit(cuda_toolkits, cuda_prerelease_toolkits)
    catch err
        # an error here would abort the Pkg operation; don't select an artifact instead.
        @debug "Could not select a CUDA toolkit" exception=err
        return nothing
    end
    cuda_toolkit === nothing && return nothing
    return "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
end

function cuda_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    # we don't actually need a comparison strategy, as the tag is known to exactly match
    # whatever toolkit artifacts we have available. however, we use one so that we can
    # bail out from downloading artifacts if the user requested a local toolkit
    if local_preference !== missing && local_preference
        return false
    end

    return a == b
end

function is_tegra()
    if isfile("/etc/nv_tegra_release")
        return true
    end
    if isfile("/proc/device-tree/compatible") &&
        contains(read("/proc/device-tree/compatible", String), "tegra")
        return true
    end
    return false
end
