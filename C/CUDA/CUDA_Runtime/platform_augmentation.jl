using Base.BinaryPlatforms

using Base: thismajor, thisminor

try
    using CUDA_Driver_jll
catch err
    # during initial package installation, CUDA_Driver_jll may not be available.
    # in that case, we just won't select an artifact (unless the user has set a preference).
end

# Can't use Preferences for the same reason
const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)

function toolkit_version(cuda_toolkits)
    # check if the user requested a specific version
    if haskey(preferences, "version")
        cuda_version_override = VersionNumber(preferences["version"])
    end
    Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")

    # if not, we need to be able to use the driver to determine the version.
    # note that we only require this when there's no override, to support
    # precompiling with a fixed version without having the driver available.
    if !@isdefined(cuda_version_override)
        if !@isdefined(CUDA_Driver_jll) ||          # see above
           !isdefined(CUDA_Driver_jll, :libcuda)    # no driver found
            return nothing
        end

        cuda_driver = CUDA_Driver_jll.libcuda_version
    end

    # "[...] applications built against any of the older CUDA Toolkits always continued
    #  to function on newer drivers due to binary backward compatibility"
    filter!(cuda_toolkits) do toolkit
        if @isdefined(cuda_version_override)
            toolkit == cuda_version_override
        elseif cuda_driver >= v"11"
            # enhanced compatibility
            #
            # "From CUDA 11 onwards, applications compiled with a CUDA Toolkit release
            #  from within a CUDA major release family can run, with limited feature-set,
            #  on systems having at least the minimum required driver version"
            thismajor(toolkit) <= thismajor(cuda_driver)
        else
            thisminor(toolkit) <= thisminor(cuda_driver)
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
