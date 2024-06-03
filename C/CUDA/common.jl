using JSON3, Downloads
using BinaryBuilder
using Base: thisminor

function get_sources(product::String, components::Vector{String};
                     version::Union{VersionNumber,String}, platform::Platform,
                     variant::Union{Nothing,String}=nothing)
    root = "https://developer.download.nvidia.com/compute/$product/redist"

    url = "$root/redistrib_$(version).json"
    json = sprint(io->Downloads.download(url, io))
    parse_sources(json, product, components; version, platform, variant)
end
# XXX: split, for now, so that we can use this with manual JSON
function parse_sources(json::String, product::String, components::Vector{String};
                       version::Union{VersionNumber,String}, platform::Platform,
                       variant::Union{Nothing,String}=nothing)
    root = "https://developer.download.nvidia.com/compute/$product/redist"

    redist = JSON3.read(json)
    architecture = if Sys.islinux(platform)
        libc(platform) == "glibc" || error("Only glibc is supported on Linux")
        if arch(platform) == "x86_64"
            "linux-x86_64"
        elseif arch(platform) == "aarch64" && platform["cuda_platform"] == "jetson"
            "linux-aarch64"
        elseif arch(platform) == "aarch64" && platform["cuda_platform"] == "sbsa"
            "linux-sbsa"
        elseif arch(platform) == "powerpc64le"
            "linux-ppc64le"
        else
            error("Unsupported Linux architecture $(arch(platform))")
        end
    elseif Sys.iswindows(platform)
        arch(platform) == "x86_64" || error("Only x86_64 is supported on Windows")
        "windows-x86_64"
    end

    sources = []
    for component in components
        if !haskey(redist, component)
            error("No such component $component for $product $version")
        end
        data = redist[component]

        if !haskey(data, architecture)
            error("No $architecture binaries for $component in $product $version")
        end
        data = data[architecture]

        if variant !== nothing
            if !haskey(data, variant)
                error("No $variant variant for $architecture $component in $product $version")
            end
            data = data[variant]
        end

        push!(sources, ArchiveSource(
            "$root/$(data["relative_path"])", data["sha256"]
        ))
    end
    sources
end

function build_sdk(name::String, version::VersionNumber, platforms::Vector{Platform};
                   static::Bool=false)
    script = "static=\"$(static)\"\n" * raw"""
install_license cuda_cudart*/LICENSE

mkdir ${prefix}/cuda
if [[ ${target} == *-linux-gnu ]]; then
    for project in *-archive; do
        cp -a ${project}/* ${prefix}/cuda
    done

    # keep or remove static libraries
    if [[ ${static} == "false" ]]; then
        find ${prefix}/cuda -type f -name "*_static*.a" -exec rm -f {} +
    else
        find ${prefix}/cuda \( -type f -o -type l \) ! -name "*_static*.a" -exec rm -f {} +
    fi
    find ${prefix}/cuda -type d -empty -delete
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    for project in *-archive; do
        cp -a ${project}/* ${prefix}/cuda
    done

    # keep or remove static libraries
    if [[ ${static} == "false" ]]; then
        find ${prefix}/cuda -type f -name "*_static*.lib" -exec rm -f {} +
    else
        find ${prefix}/cuda \( -type f -o -type l \) ! -name "*_static*.lib" -exec rm -f {} +
    fi
    find ${prefix}/cuda -type d -empty -delete

    # fixup
    find ${prefix}/cuda -type f \( -name "*.exe" -or -name "*.dll" \) -exec chmod +x {} +
fi"""

    # determine exactly which tarballs we should build
    builds = []
    components = [
        "cuda_cccl",
        "cuda_cudart",
        "cuda_cuobjdump",
        "cuda_cupti",
        "cuda_nvcc",
        "cuda_nvdisasm",
        "cuda_nvml_dev",
        "cuda_nvprune",
        "cuda_nvrtc",

        "cuda_sanitizer_api",

        "libcublas",
        "libcufft",
        "libcurand",
        "libcusolver",
        "libcusparse",
        "libnpp"
    ]
    if version >= v"11.8"
        push!(components, "cuda_profiler_api")
    end
    if version >= v"12"
        push!(components, "libnvjitlink")
    end
    if version >= v"12.2"
        # available earlier, but not for aarch64
        push!(components, "libnvjpeg")
    end
    for platform in platforms
        should_build_platform(triplet(platform)) || continue

        push!(builds,
                (; script, platforms=[platform], products=Product[],
                   sources=get_sources("cuda", components; version, platform)
        ))
    end

    # don't allow `build_tarballs` to override platform selection based on ARGS.
    # we handle that ourselves by calling `should_build_platform`
    non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

    # `--register` should only be passed to the latest `build_tarballs` invocation
    non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

    for (i,build) in enumerate(builds)
        build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                    name, version, build.sources, build.script,
                    build.platforms, build.products, [];
                    skip_audit=true)
    end
end
