using Base.BinaryPlatforms

try
    using CUDA_Runtime_jll
catch
    # during initial package installation, CUDA_Runtime_jll may not be available.
    # in that case, we just won't select an artifact.
end

# can't use Preferences for the same reason
const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)
Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")
Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "local")

function augment_platform!(platform::Platform)
    platform["cuda"] = if @isdefined(CUDA_Runtime_jll)
        cuda = CUDA_Runtime_jll.cuda_toolkit_tag()
        if cuda === nothing
            "none"
        else
            # extract major version
            cuda_version = parse(VersionNumber, cuda)
            "$(cuda_version.major)"
        end
    else
        "none"
    end

    return platform
end
