using Base.BinaryPlatforms

try
    using CUDA_Driver_jll
catch err
    # During package installation, Pkg installs all packages in parallel, so CUDA_Driver may
    # not be available yet. In that case, postpone the decision until we are able to load
    # the driver and accurately determine which CUDA Runtime to use.
    #
    # XXX: this is not a future-proof solution, as it shouldn't be possible to load any
    # non-stdlib dependencies from a package hook at any point. A better solution would be
    # to inline CUDA_Driver_jll here (while possibly renaming this artifact to CUDA_jll), so
    # that we can use the driver artifact during package installation to determine which
    # runtime artifacts to use. But that requires changes to BinaryBuilder so that we can
    # bind multiple artifacts, as well as the guarantee that it should be possible to load
    # lazy artifacts from package augmentation hooks (see JuliaLang/Pkg.jl#3225).
end

# Can't use Preferences for the same reason
const CUDA_Runtime_jll_uuid = Base.UUID("76a88914-d11a-5bdc-97e0-2f5a05c973a2")
const preferences = Base.get_preferences(CUDA_Runtime_jll_uuid)

function toolkit_version(cuda_toolkits)
    if !@isdefined(CUDA_Driver_jll) ||          # see above
       !isdefined(CUDA_Driver_jll, :libcuda)    # no driver found
        return nothing
    end

    cuda_driver = CUDA_Driver_jll.libcuda_version
    if cuda_driver < v"11"
        @error "CUDA driver 11+ is required (found $cuda_driver)."
        return nothing
    end

    # check if the user prefers a specific version
    cuda_version_override = if haskey(preferences, "version")
        VersionNumber(preferences["version"])
    else
        nothing
    end
    Base.record_compiletime_preference(CUDA_Runtime_jll_uuid, "version")

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
