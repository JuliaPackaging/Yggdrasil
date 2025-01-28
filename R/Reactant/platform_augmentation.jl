using Base.BinaryPlatforms
using Libdl
const Reactant_UUID = Base.UUID("0192cb87-2b54-54ad-80e0-3be72ad8a3c0")
const preferences = Base.get_preferences(Reactant_UUID)
Base.record_compiletime_preference(Reactant_UUID, "mode")
Base.record_compiletime_preference(Reactant_UUID, "gpu")

const mode_preference = if haskey(preferences, "mode")
    expected = ("opt", "dbg")
    if isa(preferences["mode"], String) && preferences["mode"] in expected
        preferences["mode"]
    else
        @error "Mode preference is not valid; expected $(join(expected, ", ", ", or ")), but got '$(preferences["debug"])'"
        nothing
    end
else
    nothing
end

const gpu_preference = if haskey(preferences, "gpu")
    expected = ("none", "cuda", "rocm")
    if isa(preferences["gpu"], String) && preferences["gpu"] in expected
        preferences["gpu"]
    else
        @error "GPU preference is not valid; expected $(join(expected, ", ", ", or ")), but got '$(preferences["gpu"])'"
        nothing
    end
else
    nothing
end

const cuda_version_preference = if haskey(preferences, "cuda_version")
    expected = ("none", "12.1", "12.3", "12.6")
    if isa(preferences["cuda_version"], String) && preferences["cuda_version"] in expected
        preferences["cuda_version"]
    else
        @error "CUDA version preference is not valid; expected $(join(expected, ", ", ", or ")), but got '$(preferences["cuda_version"])'"
        nothing
    end
else
    nothing
end

# adapted from `cudaRuntimeGetVersion` in CUDA_Runtime_jll
function cuDriverGetVersion(library_handle)
    function_handle = Libdl.dlsym(library_handle, "cuDriverGetVersion"; throw_error=false)
    if function_handle === nothing
        @debug "CUDA Driver library seems invalid (does not contain 'cuDriverGetVersion')"
        return nothing
    end
    version_ref = Ref{Cint}()
    status = ccall(function_handle, Cint, (Ptr{Cint},), version_ref)
    if status != 0
        @debug "Call to 'cuDriverGetVersion' failed with status $(status)"
        return nothing
    end
    major, ver = divrem(version_ref[], 1000)
    minor, patch = divrem(ver, 10)
    version = VersionNumber(major, minor, patch)
    @debug "Detected CUDA Driver version $(version)"
    return version
end

function augment_platform!(platform::Platform)

    mode = get(ENV, "REACTANT_MODE", something(mode_preference, "opt"))
    if !haskey(platform, "mode")
        platform["mode"] = mode
    end

    # "none" is for no gpu, but use "nothing" here to distinguish the case where the
    # user explicitly asked for no GPU in the preferences.
    gpu = something(gpu_preference, "undecided")

    cuda_version_tag = something(cuda_version_preference, "none")

    # Don't do GPU discovery on platforms for which we don't have GPU builds.
    # Keep this in sync with list of platforms for which we actually build with GPU support.
    if !Sys.isapple(platform)

        cuname = if Sys.iswindows()
            Libdl.find_library("nvcuda")
        else
            Libdl.find_library(["libcuda.so.1", "libcuda.so"])
        end

        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
        if cuname != "" && gpu == "undecided"
            handle = Libdl.dlopen(cuname)
            current_cuda_version = cuDriverGetVersion(handle)
            path = Libdl.dlpath(handle)
            Libdl.dlclose(handle)

            if cuda_version_tag == "none" && current_cuda_version isa VersionNumber
                if v"12.1" <= current_cuda_version < v"12.3" && arch(platform) == "x86_64"
                    cuda_version_tag = "12.1"
                elseif v"12.3" <= current_cuda_version < v"12.6"
                    cuda_version_tag = "12.3"
                elseif v"12.6" <= current_cuda_version < v"13"
                    cuda_version_tag = "12.6"
                else
                    @debug "CUDA version $(current_cuda_version) in $(path) not supported with this version of Reactant"
                end
            end

            if cuda_version_tag != "none"
                @debug "Adding include dependency on $(path)"
                Base.include_dependency(path)
                gpu = "cuda"
            end
        end

        roname = ""
        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
        if roname != "" && gpu == "undecided"
            handle = Libdl.dlopen(roname)
            path = Libdl.dlpath(handle)
            Libdl.dlclose(handle)

            @debug "Adding include dependency on $(path)"
            Base.include_dependency(path)
            gpu = "rocm"
        end

    end

    # If gpu option is still "undecided" (no preference expressed) at this point, then
    # make it "none" (no GPU support).
    if gpu == "undecided"
        gpu = "none"
    end

    gpu = get(ENV, "REACTANT_GPU", gpu)
    if !haskey(platform, "gpu")
        platform["gpu"] = gpu
    end

    gpu = get(ENV, "REACTANT_CUDA_VERSION", cuda_version_tag)
    if !haskey(platform, "cuda_version")
        platform["cuda_version"] = cuda_version_tag
    end

    return platform
end
