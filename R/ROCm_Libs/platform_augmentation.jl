# Platform augmentation for ROCm_Libs_jll.
#
# Artifacts are selected based on two platform tags:
#  - "rocm_arch": the GPU architecture family of the bundle (e.g. "gfx110x_all"),
#    matched against the devices detected on the host;
#  - "rocm": the major.minor version of the ROCm distribution the libraries were
#    taken from, selectable through the "version" preference.

using Base.BinaryPlatforms
using Base: thismajor, thisminor
using Libdl

const preferences = Base.get_preferences(ROCm_Libs_jll_uuid)
foreach(pref -> Base.record_compiletime_preference(ROCm_Libs_jll_uuid, pref),
        ("version", "local", "arch"))

function load_preference(name, expected, parse)
    haskey(preferences, name) || return missing
    parsed = parse(preferences[name])
    parsed === nothing || return parsed
    @error "ROCm $name preference is not valid; expected $expected, but got '$(preferences[name])'"
    return missing
end
const local_preference = load_preference("local", "a boolean",
    v -> v isa Bool ? v : v isa String ? tryparse(Bool, v) : nothing)
const version_preference = load_preference("version", "a version number",
    v -> v isa String ? tryparse(VersionNumber, v) : nothing)
const arch_preference = load_preference("arch", "a string (e.g. 'gfx1100')",
    v -> v isa String ? v : nothing)


## device detection

function rocm_arch_string(target::Integer)
    patch = string(target % 100, base = 16)
    return "gfx$(div(target, 10000))$(div(target, 100) % 100)$(patch)"
end

# marketing-name substrings => gfx architecture family, for hosts where we cannot
# query the driver for the real architecture (i.e. Windows)
const device_name_archs = [
    # STX Halo iGPUs: Radeon 8050S / 8060S Graphics
    ["8050s", "8060s", "device 1586"] => "gfx1151",
    # STX Point iGPUs: Radeon 880M / 890M Graphics
    ["880m", "890m"] => "gfx1150",
    # RDNA4: Radeon AI PRO R9700, RX 9070 XT/GRE, RX 9070, RX 9060 XT
    ["r9700", "9060", "9070"] => "gfx120X",
    # RDNA3: Radeon PRO V710/W7900/W7800/W7700, RX 7900 XTX/XT/GRE, RX 7800 XT, RX 7700 XT
    ["7700", "7800", "7900", "v710"] => "gfx110X",
    # RDNA2: RX 6800 XT/6800, RX 6700 XT/6700, RX 6600 XT/6600, RX 6500 XT/6500
    ["6800", "6700", "6600", "6500"] => "gfx103X",
]

function rocm_arch_from_device_name(device_name::AbstractString)
    name = lowercase(device_name)
    occursin("radeon", name) || occursin("amd", name) || return ""
    for (substrings, arch) in device_name_archs
        any(s -> occursin(s, name), substrings) && return arch
    end
    return ""
end

function rocm_arch_linux()
    topology_root = "/sys/class/kfd/kfd/topology/nodes/"
    isdir(topology_root) || return String[]

    arch = String[]
    for dir in readdir(topology_root; join = true)
        props = joinpath(dir, "properties")
        isfile(props) || continue

        for s in eachline(props)
            m = match(r"^gfx_target_version (\d+)$", s)
            m === nothing && continue

            target = parse(Int, m[1])
            target == 0 && continue

            push!(arch, rocm_arch_string(target))
        end
    end
    return arch
end

# XXX: Windows is vibe-coded and only tested at a surface level on wine
# Testers wanted!
function windows_video_device_names()
    # DISPLAY_DEVICEW layout: DWORD cb; WCHAR DeviceName[32]; WCHAR DeviceString[128];
    #                         DWORD StateFlags; WCHAR DeviceID[128]; WCHAR DeviceKey[128]
    sz = 4 + 2*32 + 2*128 + 4 + 2*128 + 2*128
    dd = Vector{UInt8}(undef, sz)
    names = String[]
    dev = 0
    while true
        fill!(dd, 0)
        dd[1:4] .= reinterpret(UInt8, UInt32[sz])  # cb = sizeof(DISPLAY_DEVICEW)
        ok = ccall((:EnumDisplayDevicesW, "user32"), stdcall, Cint,
                   (Ptr{Cvoid}, Culong, Ptr{UInt8}, Culong), C_NULL, dev, dd, 0)
        ok == 0 && break
        state_flags = reinterpret(UInt32, dd[325:328])[1]
        if state_flags & 0x00000008 == 0  # skip DISPLAY_DEVICE_MIRRORING_DRIVER pseudo-devices
            device_string = reinterpret(UInt16, dd[69:324])
            len = something(findfirst(iszero, device_string), length(device_string) + 1) - 1
            push!(names, transcode(String, device_string[1:len]))
        end
        dev += 1
    end
    return names
end

function rocm_arch()
    arch_preference !== missing && return split(arch_preference, ',')

    arch = if Sys.islinux()
        rocm_arch_linux()
    elseif Sys.iswindows()
        map(rocm_arch_from_device_name, windows_video_device_names())
    else
        String[]
    end
    filter!(!isempty, arch)
    unique!(arch)
    sort!(arch; rev = true)
    return arch
end


## "rocm_arch" tag comparison

function rocm_arch_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    a == "none" && return false
    b == "none" && return false

    a_arches = split(a, ',')
    b_arches = split(b, ',')
    for a_arch in a_arches
        for b_arch in b_arches
            rocm_arch_matches(a_arch, b_arch) && return true
            rocm_arch_matches(b_arch, a_arch) && return true
        end
    end
    return false
end

function rocm_arch_core(arch::AbstractString)
    return match(r"gfx(.*)", first(split(arch, r"[_-]", limit = 2)))[1]
end

function rocm_arch_matches(pattern::AbstractString, arch::AbstractString)
    pattern = rocm_arch_core(pattern)
    arch = rocm_arch_core(arch)

    length(pattern) == length(arch) || return false
    for (pattern_char, arch_char) in zip(pattern, arch)
        if lowercase(pattern_char) == 'x'
            isxdigit(arch_char) || lowercase(arch_char) == 'x' || return false
        elseif pattern_char != arch_char
            return false
        end
    end
    return true
end


## "rocm" version tag

# get the version of a local ROCm installation by querying the HIP runtime, if present
function get_hip_runtime_version()
    libhip = Libdl.find_library(Sys.iswindows() ? ["amdhip64_7", "amdhip64_6", "amdhip64"] :
                                                  ["libamdhip64.so.7", "libamdhip64.so.6", "libamdhip64.so"])
    if libhip == ""
        @debug "No system HIP runtime library found"
        return nothing
    end
    @debug "Found HIP runtime library at '$libhip'"

    handle = Libdl.dlopen(libhip; throw_error=false)
    handle === nothing && return nothing
    hipRuntimeGetVersion = Libdl.dlsym(handle, "hipRuntimeGetVersion"; throw_error=false)
    hipRuntimeGetVersion === nothing && return nothing

    version_ref = Ref{Cint}()
    status = ccall(hipRuntimeGetVersion, Cint, (Ptr{Cint},), version_ref)
    if status != 0
        @debug "Call to 'hipRuntimeGetVersion' failed with status $status"
        return nothing
    end
    v = version_ref[]
    major = v ÷ 10_000_000
    minor = (v ÷ 100_000) % 100
    patch = v % 100_000
    return VersionNumber(major, minor, patch)
end

# returns the value for the "rocm" tag we should use in the platform ("$MAJOR.$MINOR"),
# or nothing if no compatible ROCm distribution is available.
function rocm_version_tag()
    override = version_preference

    if local_preference === true
        # the artifact selection below never matches when using a local ROCm
        # (see `rocm_comparison_strategy`), so the tag value doesn't matter much;
        # still try to reflect the local version for informational purposes.
        if override === missing
            version = get_hip_runtime_version()
            version === nothing && return nothing
            override = version
        end
        return "$(override.major).$(override.minor)"
    end

    compatible_toolkits = override === missing ? rocm_toolkits :
        filter(toolkit -> thisminor(toolkit) == thisminor(override), rocm_toolkits)
    if isempty(compatible_toolkits)
        @error "Requested ROCm version $override does not match any supported ROCm distribution ($(join(rocm_toolkits, ", ", " or ")))"
        return nothing
    end

    rocm_toolkit = thisminor(last(compatible_toolkits))
    @debug "Selected ROCm distribution: $rocm_toolkit"
    return "$(rocm_toolkit.major).$(rocm_toolkit.minor)"
end

function rocm_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    # bail out from downloading artifacts if the user requested a local ROCm installation
    local_preference === true && return false

    # the tag is known to exactly match one of the available distributions
    return a == b
end


## entry point

function augment_platform!(platform::Platform)
    if !haskey(platform, "rocm_arch")
        arch = rocm_arch()
        platform["rocm_arch"] = isempty(arch) ? "none" : join(arch, ',')
    end
    BinaryPlatforms.set_compare_strategy!(platform, "rocm_arch", rocm_arch_comparison_strategy)

    if !haskey(platform, "rocm")
        # XXX: use "none" when we couldn't select a distribution.
        #      we can't just leave off the platform tag or Pkg would select *any* artifact.
        platform["rocm"] = something(rocm_version_tag(), "none")
    end
    BinaryPlatforms.set_compare_strategy!(platform, "rocm", rocm_comparison_strategy)

    return platform
end
