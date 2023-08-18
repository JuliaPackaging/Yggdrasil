using JSON3, Downloads
using BinaryBuilder

function get_sources(product::String="cuda", components::Vector{String}=["cuda_cudart"];
                     version::Union{VersionNumber,String}="12.2.1", platform::Platform=Platform("x86_64", "linux"))
    root = "https://developer.download.nvidia.com/compute/$product/redist"

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

    url = "$root/redistrib_$(version).json"
    json = sprint(io->Downloads.download(url, io))
    redistrib = JSON3.read(json)

    sources = []
    for component in components
        if !haskey(redistrib, component)
            error("No such component $component for $product $version")
        end
        data = redistrib[component]

        if !haskey(data, architecture)
            error("No $architecture binaries for $component in $product $version")
        end
        arch_data = data[architecture]
        push!(sources, ArchiveSource(
            "$root/$(arch_data["relative_path"])", arch_data["sha256"]
        ))
    end
    sources
end
