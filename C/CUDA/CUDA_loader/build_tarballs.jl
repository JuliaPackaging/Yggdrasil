using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_loader"
version = v"0.1"

cuda_versions = [v"9.0", v"9.2", v"10.0", v"10.2", v"11.0", v"11.1", v"11.2", v"11.3"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    for platform in platforms
        platform.tags["cuda"] = cuda_tag
    end

    any(should_build_platform.(triplet.(platforms))) || continue
    build_tarballs(ARGS, name, version, [], script, platforms, products, dependencies;
                   lazy_artifacts=true)

end
