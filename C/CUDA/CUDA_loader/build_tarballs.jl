using BinaryBuilder, Pkg

include("../../../fancy_toys.jl")

name = "CUDA_loader"
version = v"0.2.1"

cuda_versions = [v"9.0", v"9.2",
                 v"10.0", v"10.1", v"10.2",
                 v"11.0", v"11.1", v"11.2", v"11.3", v"11.4", v"11.5", v"11.6", v"11.7"]
for cuda_version in cuda_versions
    cuda_tag = "$(cuda_version.major).$(cuda_version.minor)"
    include("build_$(cuda_tag).jl")

    any(should_build_platform.(triplet.(platforms))) || continue
    build_tarballs(ARGS, name, version, [], script, platforms, products, dependencies;
                   lazy_artifacts=true)
end

# bump
