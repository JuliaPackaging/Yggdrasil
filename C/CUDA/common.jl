using JSON3, Downloads
using BinaryBuilder

function get_sources(product::String, components::Vector{String};
                     version::Union{VersionNumber,String}, platform::Platform,
                     variant::Union{Nothing,String}=nothing)
    root = "https://developer.download.nvidia.com/compute/$product/redist"

    url = "$root/redistrib_$(version).json"
    json = sprint(io->Downloads.download(url, io))
    parse_sources(json, product, components; version, platform)
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
        elseif arch(platform) == "aarch64"
            # XXX: 11.7+ also has linux-aarch64
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
