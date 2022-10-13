using Libdl

using CUDA_Driver

using Base.BinaryPlatforms

function driver_version()
    if libcuda() === nothing
        return nothing
    end

    libcuda_handle = Libdl.dlopen(libcuda())
    try
        function_handle = Libdl.dlsym(libcuda_handle, "cuDriverGetVersion")
        version_ref = Ref{Cint}()
        status = ccall(function_handle, UInt32, (Ptr{Cint},), version_ref)
        if status != 0
            # TODO: warn here about the error?
            return nothing
        end
        major, ver = divrem(version_ref[], 1000)
        minor, patch = divrem(ver, 10)
        return VersionNumber(major, minor, patch)
    finally
        Libdl.dlclose(libcuda_handle)
    end
end

function toolkit_version(cuda_toolkits)
    cuda_driver = driver_version()
    if cuda_driver === nothing
        return nothing
    elseif cuda_driver < v"11"
        @error "CUDA driver 11+ is required (found $cuda_driver)."
        return nothing
    end

    cuda_version_override = get(ENV, "JULIA_CUDA_VERSION", nothing)
    if cuda_version_override === ""
        return nothing
    elseif cuda_version_override !== nothing
        cuda_version_override = VersionNumber(cuda_version_override)
    end
    # TODO: support for Preferences.jl-based override?

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    filter!(cuda_toolkits) do toolkit
        if cuda_version_override !== nothing
            toolkit == cuda_version_override
        else
            # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
            #  from within a CUDA major release family can run, with limited feature-set,
            #  on systems having at least the minimum required driver version"
            toolkit.major <= cuda_driver.major
        end
    end
    if isempty(cuda_toolkits)
        return nothing
    end

    last(cuda_toolkits)
end

# versions will be provided by build_tarballs.jl
function augment_platform!(platform::Platform, cuda_toolkits::Vector{VersionNumber})
    haskey(platform, "cuda") && return platform

    cuda_toolkit = toolkit_version(cuda_toolkits)
    platform["cuda"] = if cuda_toolkit !== nothing
        "$(cuda_toolkit.major).$(cuda_toolkit.minor)"
    else
        # don't use an empty string here, because Pkg will then load *any* artifact
        "none"
    end

    return platform
end
