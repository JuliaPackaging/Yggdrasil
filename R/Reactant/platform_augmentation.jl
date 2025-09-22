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

const cuda_version_preference = if haskey(preferences, "gpu_version")
    expected = ("none", "12.6", "12.8", "13.0", "7.0")
    if isa(preferences["gpu_version"], String) && preferences["gpu_version"] in expected
        preferences["gpu_version"]
    else
        @error "GPU version preference is not valid; expected $(join(expected, ", ", ", or ")), but got '$(preferences["gpu_version"])'"
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

function amdDriverInitialized()::Bool
    amdgpu_module_path = "/sys/module/amdgpu"

    # First, check if the driver's module directory exists.
    if isdir(amdgpu_module_path)
        initstate_path = joinpath(amdgpu_module_path, "initstate")

        if isfile(initstate_path)
            # Case 1: The driver is a loadable module.
            # We need to read its state to see if it's 'live'.
            # The `open...do` block ensures the file is closed automatically.
            return open(initstate_path) do file
                contains(read(file, String), "live")
            end
        else
            # Case 2: The directory exists but `initstate` does not.
            # This implies the driver is built into the kernel and is active.
            return true
        end
    end

    # If the directory doesn't exist, the driver isn't available.
    return false
end


function augment_platform!(platform::Platform)

    mode = get(ENV, "REACTANT_MODE", something(mode_preference, "opt"))
    if !haskey(platform, "mode")
        platform["mode"] = mode
    end

    # "none" is for no gpu, but use "nothing" here to distinguish the case where the
    # user explicitly asked for no GPU in the preferences.
    gpu = something(gpu_preference, "undecided")

    gpu_version_tag = something(gpu_version_preference, "none")

    # Don't do GPU discovery on platforms for which we don't have GPU builds.
    # Keep this in sync with list of platforms for which we actually build with GPU support.
    if !Sys.isapple(platform) && !Sys.iswindows()

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
                if v"12.6" <= current_cuda_version < v"12.8"
                    gpu_version_tag = "12.6"
                elseif v"12.8" <= current_cuda_version < v"13"
                    gpu_version_tag = "12.8"
                elseif v"13.0" <= current_cuda_version < v"14" && arch(platform) == "x86_64"
                    gpu_version_tag = "13.0"
                else
                    @warn "CUDA version $(current_cuda_version) in $(path) not supported with this version of Reactant (min supported: 12.6)"
                end
            end

            if gpu_version_tag != "none"
                @debug "Adding include dependency on $(path)"
                Base.include_dependency(path)
                gpu = "cuda"
            end
        end

        # if we've found a system driver, put a dependency on it,
        # so that we get recompiled if the driver changes.
	if amdDriverInitialized() && gpu == "undecided"
            #roname = ""
            #handle = Libdl.dlopen(roname)
            #path = Libdl.dlpath(handle)
            #Libdl.dlclose(handle)
	    gpu_version_tag = "7.0"

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

    gpu_version_tag = get(ENV, "REACTANT_GPU_VERSION", gpu_version_tag)
    if !haskey(platform, "gpu_version")
        platform["gpu_version"] = gpu_version_tag
    end

    return platform
end
