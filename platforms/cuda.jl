module CUDA

using Pkg

using BinaryBuilder

using Base.BinaryPlatforms
using Base.BinaryPlatforms: arch, os, tags

# the "cuda" platform tag contains the major and minor version of the CUDA runtime loaded
# by CUDA_Runtime_jll, and is used to select artifacts that depend on the CUDA runtime.

const augment = """
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
    const local_toolkit = something(tryparse(Bool, get(preferences, "local", "false")), false)

    function cuda_comparison_strategy(_a::String, _b::String, a_requested::Bool, b_requested::Bool)
        # if we're using a local toolkit, we can't use artifacts
        if local_toolkit
            return false
        end

        # if either isn't a version number (e.g. "none"), perform a simple equality check
        a = tryparse(VersionNumber, _a)
        b = tryparse(VersionNumber, _b)
        if a === nothing || b === nothing
            return _a == _b
        end

        # if both b and a requested, then we fall back to equality
        if a_requested && b_requested
            return Base.thisminor(a) == Base.thisminor(b)
        end

        # otherwise, do the comparison between the the single version cap and the single version:
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            if host >= v"11.0"
                # enhanced compatibility, semver-style
                artifact.major == host.major &&
                Base.thisminor(artifact) <= Base.thisminor(host)
            else
                Base.thisminor(artifact) == Base.thisminor(host)
            end
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_platform!(platform::Platform)
        if !@isdefined(CUDA_Runtime_jll)
            # don't set to nothing or Pkg will download any artifact
            platform["cuda"] = "none"
        end

        if !haskey(platform, "cuda")
            CUDA_Runtime_jll.augment_platform!(platform)
        end
        BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)

        return platform
    end"""

# a special version of the platform augmentation block that only sets "cuda_platform"
# (for use with packages that only ship a single version and don't depend on the runtime)
# XXX: keep in sync with CUDA_Runtime_jll's platform augmentation
const platform_augment = """
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

    function augment_platform!(platform::Platform)
        haskey(platform, "cuda_platform") && return platform

        if Sys.islinux() && arch(platform) == "aarch64"
            platform["cuda_platform"] = if is_tegra()
                "jetson"
            else
                "sbsa"
            end
        end

        return platform
    end"""

function platform(cuda::VersionNumber)
    return "$(cuda.major).$(cuda.minor)"
end
platform(cuda::String) = cuda

# BinaryBuilder.jl currently does not allow selecting a BuildDependency by compat,
# so we need the full version for CUDA_SDK_jll (JuliaPackaging/BinaryBuilder.jl#/1212).
const cuda_full_versions = [
    v"10.2.89",
    v"11.4.4",
    v"11.5.2",
    v"11.6.2",
    v"11.7.1",
    v"11.8.0",
    v"12.0.1",
    v"12.1.1",
    v"12.2.2",
    v"12.3.2",
    v"12.4.1",
    v"12.5.1",
    v"12.6.3",
    v"12.8.1",
]

function full_version(ver::VersionNumber)
    ver == Base.thisminor(ver) || error("Cannot specify a patch version")
    for full_ver in cuda_full_versions
        if ver == Base.thisminor(full_ver)
            return full_ver
        end
    end
    error("CUDA version $ver not supported")
end

"""
    supported_platforms(; <keyword arguments>)

Return a list of supported platforms to build CUDA artifacts for.

# Arguments
- `min_version=v"11"`: Min. CUDA version to target.
- `max_version=nothing`: Max. CUDA version to target.
"""
function supported_platforms(; min_version=v"11", max_version=nothing)
    base_platforms = [
        Platform("x86_64", "linux"; libc = "glibc"),
        Platform("aarch64", "linux"; libc = "glibc", cuda_platform="jetson"),
        Platform("aarch64", "linux"; libc = "glibc", cuda_platform="sbsa"),

        # nvcc isn't a cross compiler, so incompatible with BinaryBuilder
        #Platform("x86_64", "windows"),
    ]

    cuda_versions = filter(v -> (isnothing(min_version) || v >= min_version) &&
                                (isnothing(max_version) || v <= max_version),
                           cuda_full_versions)

    # augment with CUDA versions
    platforms = Platform[]
    for version in cuda_versions
        for base_platform in base_platforms
            platform = deepcopy(base_platform)

            if arch(platform) == "aarch64"
                # CUDA 10.x: our CUDA 10.2 build recipe for arm64 only provides jetson binaries
                if Base.thisminor(version) == v"10.2" && platform["cuda_platform"] != "jetson"
                    continue
                end

                # CUDA 11.x: only 11.8 has jetson binaries on the redist server
                if v"11.0" <= Base.thisminor(version) < v"11.8" && platform["cuda_platform"] == "jetson"
                    continue
                end

                # CUDA 12.x: the jetson binaries for 12.3 seem to be missing
                if Base.thisminor(version) == v"12.3" && platform["cuda_platform"] == "jetson"
                    continue
                end
            end

            platform["cuda"] = "$(version.major).$(version.minor)"
            push!(platforms, platform)
        end
    end

    return platforms
end

"""
    is_supported(platform)

Check if a platform is supported by CUDA, and whether we can build artifacts for it.
This can be used to determine whether to also provide a `cuda+none` build, which should
only ever be used if there is _also_ a CUDA-enabled build available.
"""
function is_supported(platform)
    if Sys.islinux(platform)
        return arch(platform) in ["x86_64", "aarch64", "powerpc64le"]
    elseif Sys.iswindows(platform)
        # see note in `supported_platforms()`
        return false
    else
        return false
    end
end

"""
    required_dependencies(platform; static_sdk=false)

Return a list of dependencies required to build and use CUDA artifacts for a given platform.
Optionally include the CUDA static libraries with `static_sdk` for toolchains that require them.
"""
function required_dependencies(platform; static_sdk=false)
    dependencies = Dependency[]
    if !haskey(tags(platform), "cuda") || tags(platform)["cuda"] == "none"
        return BinaryBuilder.AbstractDependency[]
    end
    release = VersionNumber(tags(platform)["cuda"])
    deps = BinaryBuilder.AbstractDependency[
        BuildDependency(PackageSpec(name="CUDA_SDK_jll", version=CUDA.full_version(release))),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))
    ]

    if static_sdk
        push!(deps, BuildDependency(PackageSpec(name="CUDA_SDK_static_jll", version=CUDA.full_version(release))))
    end

    return deps
end

"""
    cuda_nvcc_redist_source(cuda_ver, arch)

Returns an ArchiveSource for the official NVIDIA redist of the given CUDA version and architecture.
"""
function cuda_nvcc_redist_source(cuda_ver, arch)
    if arch == "x86_64"
        if cuda_ver == "11.8"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_11.8.0.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-11.8.89-archive.tar.xz",
                          "7ee8450dbcc16e9fe5d2a7b567d6dec220c5894a94ac6640459e06231e3b39a5")
        elseif cuda_ver == "12.0"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.0.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.0.140-archive.tar.xz",
                          "906b894dffd853acefe6ab3d2a6cd74a0aa99b34bb8ca1e848174bddf55bfa3b")
        elseif cuda_ver == "12.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.1.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.1.105-archive.tar.xz",
                          "0b85f7eee17788abbd170b0b493c74ce2e9fd5a9604461b99c2c378165e1083b")
        elseif cuda_ver == "12.2"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.2.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.2.128-archive.tar.xz",
                           "018086c6bce5868451b0d30c74fd78826e15a2af0e9d891c1843bc2c3884bdec")
        elseif cuda_ver == "12.3"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.3.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.3.103-archive.tar.xz",
                           "ae86efce6a69e99c55def1203157aee4bf71d6e5f8423c2a8d69a0e97036e9db")
        elseif cuda_ver == "12.4"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.4.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.4.131-archive.tar.xz",
                          "7ffba1ada0e4b8c17e451ac7a60d386aa2642ecd08d71202a0b100c98bd74681")
        elseif cuda_ver == "12.5"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.5.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.5.82-archive.tar.xz",
                          "ded05fe3c8d075c6c1bf892005d3c50bde3eceaa049b879fcdff6158e068e3be")
        elseif cuda_ver == "12.6"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.6.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.6.68-archive.tar.xz",
                          "b672d0c36a27ea4577536725713064c9daa5d7378ac85877bc847ca9a46b2645")
        elseif cuda_ver == "12.8"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.8.1.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.8.93-archive.tar.xz",
                         "9961b3484b6b71314063709a4f9529654f96782ad39e72bf1e00f070db8210d3")
        else
            error("No CUDA redist available for CUDA version $cuda_ver on arch $arch")
        end
    else
        error("No CUDA redist available for arch $arch")
    end
end

end
