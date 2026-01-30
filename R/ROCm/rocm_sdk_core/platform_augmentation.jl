using Base.BinaryPlatforms

const rocm_sdk_core_jll_uuid = Base.UUID("9ab9228b-5f62-5ec0-95ae-72487824505f")
const preferences = Base.get_preferences(rocm_sdk_core_jll_uuid)
Base.record_compiletime_preference(rocm_sdk_core_jll_uuid, "local")

const local_preference = if haskey(preferences, "local")
    if isa(preferences["local"], Bool)
        preferences["local"]
    elseif isa(preferences["local"], String)
        use_local = tryparse(Bool, preferences["local"])
        if use_local === nothing
            @error "ROCm local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
            missing
        else
            use_local
        end
    else
        @error "ROCm local preference is not valid; expected a boolean, but got '$(preferences["local"])'"
        missing
    end
else
    missing
end

try
    using HSARuntime_jll
catch
    # during initial package installation, HSARuntime_jll may not be available.
    # in that case, we just won't select an artifact.
end

struct hsa_agent_t
    handle::UInt64
end

const HSA_AGENT_INFO_NAME::Cint = 0

@enum hsa_status_t::Cint begin
    HSA_STATUS_SUCCESS                      = 0x0
    HSA_STATUS_INFO_BREAK                   = 0x1

    HSA_STATUS_ERROR                        = 0x1000
    HSA_STATUS_ERROR_INVALID_ARGUMENT        = 0x1001
    HSA_STATUS_ERROR_INVALID_QUEUE_CREATION  = 0x1002
    HSA_STATUS_ERROR_INVALID_ALLOCATION      = 0x1003
    HSA_STATUS_ERROR_INVALID_AGENT           = 0x1004
    HSA_STATUS_ERROR_INVALID_REGION          = 0x1005
    HSA_STATUS_ERROR_INVALID_SIGNAL          = 0x1006
    HSA_STATUS_ERROR_INVALID_QUEUE           = 0x1007
    HSA_STATUS_ERROR_OUT_OF_RESOURCES        = 0x1008
    HSA_STATUS_ERROR_INVALID_PACKET_FORMAT   = 0x1009
    HSA_STATUS_ERROR_RESOURCE_FREE           = 0x100A
    HSA_STATUS_ERROR_NOT_INITIALIZED         = 0x100B
    HSA_STATUS_ERROR_REFCOUNT_OVERFLOW       = 0x100C
    HSA_STATUS_ERROR_INCOMPATIBLE_ARGUMENTS  = 0x100D
    HSA_STATUS_ERROR_INVALID_INDEX           = 0x100E
    HSA_STATUS_ERROR_INVALID_ISA             = 0x100F

    HSA_STATUS_ERROR_INVALID_CODE_OBJECT     = 0x1010
    HSA_STATUS_ERROR_INVALID_EXECUTABLE      = 0x1011
    HSA_STATUS_ERROR_FROZEN_EXECUTABLE       = 0x1012
    HSA_STATUS_ERROR_INVALID_SYMBOL_NAME     = 0x1013
    HSA_STATUS_ERROR_VARIABLE_ALREADY_DEFINED = 0x1014
    HSA_STATUS_ERROR_VARIABLE_UNDEFINED      = 0x1015
    HSA_STATUS_ERROR_EXCEPTION               = 0x1016
    HSA_STATUS_ERROR_INVALID_ISA_NAME        = 0x1017
    HSA_STATUS_ERROR_INVALID_CODE_SYMBOL     = 0x1018
    HSA_STATUS_ERROR_INVALID_EXECUTABLE_SYMBOL = 0x1019

    HSA_STATUS_ERROR_INVALID_FILE            = 0x1020
    HSA_STATUS_ERROR_INVALID_CODE_OBJECT_READER = 0x1021
    HSA_STATUS_ERROR_INVALID_CACHE           = 0x1022
    HSA_STATUS_ERROR_INVALID_WAVEFRONT       = 0x1023
    HSA_STATUS_ERROR_INVALID_SIGNAL_GROUP    = 0x1024
    HSA_STATUS_ERROR_INVALID_RUNTIME_STATE   = 0x1025
    HSA_STATUS_ERROR_FATAL                   = 0x1026
end

function callback(agent::hsa_agent_t, data::Ptr{Vector{String}})
    a = Base.unsafe_pointer_to_objref(data)
    _name = zeros(Cchar, 64)
    status = @ccall libhsa_runtime64.hsa_agent_get_info(agent::hsa_agent_t, HSA_AGENT_INFO_NAME::Cint, _name::Ptr{Cchar})::hsa_status_t
    if status == HSA_STATUS_SUCCESS
        GC.@preserve _name push!(a, Base.unsafe_string(pointer(_name)))
    end
    return status
end

function agent_names()
    r = Ref(String[])
    ptr = Base.unsafe_convert(Ptr{Vector{String}}, r)
    cb = @cfunction(callback, hsa_status_t, (hsa_agent_t, Ptr{Vector{String}}))
    status = @ccall libhsa_runtime64.hsa_init()::hsa_status_t
    status != HSA_STATUS_SUCCESS && error(status)
    status = @ccall libhsa_runtime64.hsa_iterate_agents(cb::Ptr{Cvoid}, ptr::Ptr{Vector{String}})::hsa_status_t
    status != HSA_STATUS_SUCCESS && error(status)
    status = @ccall libhsa_runtime64.hsa_shut_down()::hsa_status_t
    status != HSA_STATUS_SUCCESS && error(status)
    return r[]
end

function name_to_platform(name::String)
    if startswith(name, "gfx101")
        return "gfx101x_dgpu"
    elseif startswith(name, "gfx103")
        return "gfx103x_dgpu"
    elseif startswith(name, "gfx110")
        return "gfx110x_all"
    elseif name == "gfx1150"
        return "gfx1150"
    elseif name == "gfx1151"
        return "gfx1151"
    elseif startswith(name, "gfx120")
        return "gfx120x_all"
    elseif startswith(name, "gfx90")
        return "gfx90x_dcgpu"
    elseif startswith(name, "gfx94")
        return "gfx94x_dcgpu"
    elseif startswith(name, "gfx950")
        return "gfx950_dcgpu"
    else
        return nothing
    end
end

function detect_rocm_platform()
    names = try
        agent_names()
    catch e
        @warn "Failed to detect ROCm platform: $e"
        String[]
    end
    filter!(startswith("gfx"), names)

    if isempty(names)
        @warn "No ROCm GPU agents detected on this system."
        return "none"
    end

    platforms = unique!(filter(!isnothing, map(name_to_platform, names)))
    if isempty(platforms)
        @warn "Unrecognized ROCm GPU agents detected on this system: $(join(names, ", "))."
        return "none"
    elseif length(platforms) > 1
        @warn "Multiple supported ROCm platforms detected on this system: $(join(platforms, ", ")). Using the first one. Override by setting the `rocm_platform` preference."
    end

    return first(platforms)
end

function augment_platform!(platform::Platform)
    # Only augment Linux x86_64 platforms
    if Sys.islinux() && arch(platform) == "x86_64"
        if !haskey(platform, "rocm_platform")
            platform["rocm_platform"] = detect_rocm_platform()
        end

        # Store the fact that we're using a local ROCm installation
        platform["rocm_local"] = string(local_preference !== missing && local_preference)
    end

    return platform
end
