module CUDA

const platform_name = "cuda"
const augment = """
    using Libdl
    using Base: thisminor
    using Base.BinaryPlatforms: set_compare_strategy!


    #
    # Augmentation for selecting the CUDA toolkit
    #

    # NOTE: we set the 'cuda' platform tag to the actual CUDA Toolkit version we'll be using
    #       and not to the version that this driver supports (letting Pkg select an artifact
    #       via a comparison strategy). This to simplify dependent packages; otherwise they
    #       would need to know which toolkits are available to additionaly bound selection.

    # provided by caller: `augment_cuda_toolkit!(platform)` method calling the version below
    #                     with the available toolkit versions passed along

    function driver_version()
        libcuda_path = if Sys.iswindows()
            Libdl.find_library("nvcuda")
        else
            Libdl.find_library(["libcuda.so.1", "libcuda.so"])
        end
        if libcuda_path == ""
            return nothing
        end

        libcuda = Libdl.dlopen(libcuda_path)
        try
            function_handle = Libdl.dlsym(libcuda, "cuDriverGetVersion")
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
            Libdl.dlclose(libcuda)
        end
    end

    function toolkit_version(cuda_toolkits)
        cuda_driver = driver_version()
        if cuda_driver === nothing
            return nothing
        end

        cuda_version_override = get(ENV, "JULIA_CUDA_VERSION", nothing)
        # TODO: support for Preferences.jl-based override?

        # "[...] applications built against any of the older CUDA Toolkits always continued
        #  to function on newer drivers due to binary backward compatibility"
        filter!(cuda_toolkits) do toolkit
            if cuda_version_override !== nothing
                toolkit == cuda_version_override
            elseif cuda_driver >= v"11.1"
                # enhanced compatibility
                #
                # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
                #  from within a CUDA major release family can run, with limited feature-set,
                #  on systems having at least the minimum required driver version"
                # TODO: check this minimum required driver version?
                toolkit.major <= cuda_driver.major
            else
                thisminor(toolkit) <= thisminor(cuda_driver)
            end
        end
        if isempty(cuda_toolkits)
            return nothing
        end

        last(cuda_toolkits)
    end

    function augment_cuda_toolkit!(platform::Platform, cuda_toolkits::Vector{VersionNumber})
        haskey(platform, "cuda") && return platform

        cuda_toolkit = toolkit_version(cuda_toolkits)
        platform["cuda"] = if cuda_toolkit !== nothing
            "\$(cuda_toolkit.major).\$(cuda_toolkit.minor)"
        else
            # don't use an empty string here, because Pkg will then load *any* artifact
            "none"
        end

        return platform
    end


    #
    # Augmentation for selecting artifacts that depend on the CUDA toolkit
    #

    # imported by caller: CUDA_Runtime_jll

    function cuda_comparison_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
        a = VersionNumber(a)
        b = VersionNumber(b)

        # If both b and a requested, then we fall back to equality:
        if a_requested && b_requested
            return a == b
        end

        # Otherwise, do the comparison between the the single version cap and the single version:
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            if host >= v"11.0"
                # enhanced compatibility, semver-style
                artifact.major == host.major
            else
                artifact.major == host.major &&
                artifact.minor == host.minor
            end
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_cuda_dependent!(platform::Platform)
        if !haskey(platform, "cuda")
            platform = CUDA_Runtime_jll.augment_cuda_toolkit!(platform)
        end
        set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)
        return platform
    end"""

function platform(cuda::VersionNumber)
    return "$(cuda.major).$(cuda.minor)"
end

end
