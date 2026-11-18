module CUDA

using Pkg

using BinaryBuilder

using Base.BinaryPlatforms
using Base.BinaryPlatforms: arch, os, tags

# the "cuda" platform tag contains the major and minor version of the CUDA runtime loaded
# by CUDA_Runtime_jll, and is used to select artifacts that depend on the CUDA runtime.

# shared by `augment` and `augment_with`; they add the `augment_platform!` entry point.
# CUDA_Runtime_jll owns the selection logic, so that its releases fix every JLL using it.
const augment_definitions = """
    using Base.BinaryPlatforms

    try
        using CUDA_Runtime_jll
    catch
        # during initial package installation, CUDA_Runtime_jll may not be available.
    end

    # every other tag that artifacts are selected on must be set before calling this
    function augment_cuda_tag!(platform::Platform)
        if @isdefined(CUDA_Runtime_jll) && isdefined(CUDA_Runtime_jll, :augment_dependent!)
            # both Pkg and the JLL module include this file from the JLL's `.pkg` directory
            artifacts_toml = joinpath(@__DIR__, "..", "Artifacts.toml")
            CUDA_Runtime_jll.augment_dependent!(platform, artifacts_toml)
        elseif !haskey(platform, "cuda")
            # CUDA_Runtime_jll is missing during initial installation, or briefly older than
            # our compat bound while Pkg changes the environment. select the CPU build, if
            # any; without the tag, Pkg would select any build.
            platform["cuda"] = "none"
        end
        return platform
    end"""

# the CUDA_Runtime_jll release that provides `augment_dependent!`
const runtime_compat = "0.26.1 - 0"

"""
    augment

Platform augmentation block for JLLs whose artifacts depend on the CUDA runtime. A JLL
without an artifact for the selected toolkit selects its `cuda=none` artifact, if any. To
combine it with another tag's block, use [`augment_with`](@ref).

Keep its `function augment_platform!` definition in long form: `M/MPICH_CUDA` renames it
with `replace`.
"""
const augment = augment_definitions * """\n
    function augment_platform!(platform::Platform)
        augment_cuda_tag!(platform)
    end"""

"""
    augment_with(block, call)

Platform augmentation block that runs `call` from `block`, then sets the CUDA tag, e.g.
`CUDA.augment_with(MPI.augment, "augment_mpi!")`. The CUDA tag goes last: the fallback to
the CPU build needs every other tag.
"""
augment_with(block::String, call::String) = """
    using Base.BinaryPlatforms

    $block

    $augment_definitions

    function augment_platform!(platform::Platform)
        $call(platform)
        augment_cuda_tag!(platform)
    end"""

# augmentation block for artifacts that depend on the CUDA compiler (i.e., the JIT
# stack: nvrtc/nvJitLink) rather than on the CUDA runtime. selection follows
# CUDA_Compiler_jll, which picks a toolkit independently from the runtime. the "cuda"
# tag names the oldest compatible toolkit series, so an artifact also matches newer
# JIT stacks from the same major series. unlike CUDA_Compiler_jll's own artifacts,
# dependent artifacts may still be used with a compatible local toolkit.
const compiler_augment = """
    using Base.BinaryPlatforms

    try
        using CUDA_Compiler_jll
    catch
        # during initial package installation, CUDA_Compiler_jll may not be available.
        # in that case, we just won't select an artifact.
    end

    function cuda_comparison_strategy(_a::String, _b::String, a_requested::Bool, b_requested::Bool)
        # if either isn't a version number (e.g. "none"), perform a simple equality check
        a = tryparse(VersionNumber, _a)
        b = tryparse(VersionNumber, _b)
        if a === nothing || b === nothing
            return _a == _b
        end

        # if both are explicitly requested, require equality
        if a_requested && b_requested
            return Base.thisminor(a) == Base.thisminor(b)
        end

        # otherwise, an artifact is compatible with a JIT stack from the same major
        # series that is at least as new as the artifact's minimum toolkit
        function is_compatible(artifact::VersionNumber, host::VersionNumber)
            artifact.major == host.major &&
            Base.thisminor(artifact) <= Base.thisminor(host)
        end
        if a_requested
            is_compatible(b, a)
        else
            is_compatible(a, b)
        end
    end

    function augment_platform!(platform::Platform)
        if !@isdefined(CUDA_Compiler_jll)
            # don't set to nothing or Pkg will download any artifact
            platform["cuda"] = "none"
        elseif !haskey(platform, "cuda")
            # CUDA_Compiler_jll owns driver inspection and preference handling.
            CUDA_Compiler_jll.augment_platform!(platform)
        end
        BinaryPlatforms.set_compare_strategy!(platform, "cuda", cuda_comparison_strategy)

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
    v"12.9.1",
    v"13.0.2",
    v"13.1.1",
    v"13.2.1",
    v"13.3.1",
    v"13.4.3",
    v"13.5.0"
]

# EA/preview toolkits. We do build JLLs for these, so that they can be used explicitly,
# but they are never selected automatically: they are left out of `supported_platforms`
# unless asked for, and CUDA_Runtime_jll's platform augmentation only ever picks one when
# the user requests it through the "version" preference.
const cuda_prerelease_versions = VersionNumber[]

function full_version(ver::VersionNumber)
    ver == Base.thisminor(ver) || error("Cannot specify a patch version")
    for full_ver in [cuda_full_versions; cuda_prerelease_versions]
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
- `prereleases=false`: Also target EA/preview toolkits (`cuda_prerelease_versions`).
"""
function supported_platforms(; min_version=v"11", max_version=nothing,
                               prereleases::Bool=false)
    base_platforms = [
        Platform("x86_64", "linux"; libc = "glibc"),
        Platform("aarch64", "linux"; libc = "glibc", cuda_platform = "jetson"),
        Platform("aarch64", "linux"; libc = "glibc", cuda_platform = "sbsa"),
        Platform("aarch64", "linux"; libc = "glibc"),

        # nvcc isn't a cross compiler, so incompatible with BinaryBuilder
        #Platform("x86_64", "windows"),
    ]

    candidate_versions = prereleases ? [cuda_full_versions; cuda_prerelease_versions] :
                                       cuda_full_versions
    cuda_versions = filter(v -> (isnothing(min_version) || v >= min_version) &&
                                (isnothing(max_version) || v <= max_version),
                           candidate_versions)

    # augment with CUDA versions
    platforms = Platform[]
    for version in cuda_versions
        for base_platform in base_platforms
            platform = deepcopy(base_platform)

            if arch(platform) == "aarch64"
                # CUDA 13.x: we don't distinguish between jetson and sbsa any more
                if version >= v"13" && haskey(platform, "cuda_platform")
                    continue
                end
                if version < v"13" && !haskey(platform, "cuda_platform")
                    continue
                end

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

Whether CUDA builds could exist for `platform`.
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
    required_dependencies(platforms::AbstractVector; static_sdk=false)

Dependencies for building and using the CUDA builds among `platforms`, each limited to
the platforms that need it. `static_sdk` adds the static CUDA libraries.

Pass the same list to every `build_tarballs` call: the last call writes the JLL's
Project.toml. Tag the CPU platforms with [`cpu_platforms`](@ref).
"""
function required_dependencies(platforms::AbstractVector; static_sdk=false)
    cuda_platforms = filter(p -> get(tags(p), "cuda", "none") != "none", platforms)
    deps = BinaryBuilder.AbstractDependency[]
    for release in unique(p["cuda"] for p in cuda_platforms)
        release_platforms = filter(p -> p["cuda"] == release, cuda_platforms)
        version = string(full_version(VersionNumber(release)))
        push!(deps, BuildDependency(PackageSpec(; name="CUDA_SDK_jll", version); platforms=release_platforms))
        static_sdk && push!(deps, BuildDependency(PackageSpec(; name="CUDA_SDK_static_jll", version); platforms=release_platforms))
    end
    isempty(cuda_platforms) ||
        push!(deps, RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"); compat=runtime_compat,
                                     platforms=cuda_platforms))
    return deps
end
required_dependencies(platform; static_sdk=false) = required_dependencies([platform]; static_sdk)

"""
    cpu_platforms(platforms)

Copies of `platforms` for the CPU builds of a JLL that also has CUDA builds, tagged
`cuda=none`. Every CPU build needs the tag: an untagged one would match CUDA hosts.
"""
function cpu_platforms(platforms)
    map(platforms) do platform
        platform = deepcopy(platform)
        platform["cuda"] = "none"
        platform
    end
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
        elseif cuda_ver == "12.9"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_12.9.0.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-12.9.41-archive.tar.xz",
                          "b3a0e115840e04c0cfa559263cbbe8b78a2455788e12605732aff68abc50dd34")
        elseif cuda_ver == "13.0"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.0.0.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-13.0.48-archive.tar.xz",
                          "cc5ff4a00d3be7c6c86ff740de7672e142ec87fea74e7e46b1b142b59fd2ac51")
        elseif cuda_ver == "13.1"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.1.0.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-13.1.80-archive.tar.xz",
                          "5ed3b7cfe7f12557199773e7769445357ee048958ff51e623e15f36d3393ca8b")
        elseif cuda_ver == "13.2"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.2.0.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-13.2.51-archive.tar.xz",
                          "706b996fefc59dc8d64d317fdf48d0aa84c4ae004eff43009dd918f40c5cc66a")
        elseif cuda_ver == "13.4"
            # See https://developer.download.nvidia.com/compute/cuda/redist/redistrib_13.4.2.json
            ArchiveSource("https://developer.download.nvidia.com/compute/cuda/redist/cuda_nvcc/linux-x86_64/cuda_nvcc-linux-x86_64-13.4.92-archive.tar.xz",
                          "60998f40cc9df5826b2a846e2dcc328133fbc5ef539398ce0a21cf5dcac7193d")
        else
            error("No CUDA redist available for CUDA version $cuda_ver on arch $arch")
        end
    else
        error("No CUDA redist available for arch $arch")
    end
end

"""
    cuda_gpu_archs(platform::Platform)

Returns a list of the GPU architectures supported by the given CUDA platform.
"""
function cuda_gpu_archs(platform::Platform)
    ver = VersionNumber(tags(platform)["cuda"])
    cuda_gpu_archs(ver)
end

"""
    cuda_gpu_archs(cuda_ver)

Returns a list of the GPU architectures supported by the given CUDA version.
"""
function cuda_gpu_archs(cuda_ver)
    # List roughly based on https://arnon.dk/matching-sm-architectures-arch-and-gencode-for-various-nvidia-cards/

    # CUDA 10 and later
    supported_archs = [
        "75",       # sm_75 -> Turing (RTX 20xx, T4)
        ]

    if cuda_ver >= v"11.1"
        push!(supported_archs, "80")        # sm_80 -> Ampere (A100)
        push!(supported_archs, "86")        # sm_86 -> Ampere (A40, RTX 30xx, RTX Ax000 Ada)
    end


    if cuda_ver >= v"11.8"
        push!(supported_archs, "89")        # sm_89 -> Ada lovelace (RTX 4090/4080, L40)
    end

    if cuda_ver >= v"12.0"
        push!(supported_archs, "90")        # sm_90 -> Hopper (H100, H200) - PTX 8.0
    end

    if cuda_ver >= v"12.8"
        push!(supported_archs, "100")       # sm_100 -> Blackwell (B100, B200)
        push!(supported_archs, "120")       # sm_120 -> Blackwell (RTX 50xx, RTX PRO x000 BLACKWELL)
    end

    if cuda_ver >= v"12.9"
        push!(supported_archs, "103")       # sm_103 -> Blackwell (B300, GB300)
        push!(supported_archs, "121")       # sm_121 -> Blackwell (DGX SPARK, DIGITS)
    end

    supported_archs
end

end
