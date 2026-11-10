using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

name = "OpenCV_CUDA"

include(joinpath(@__DIR__, "..", "common.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "C", "CUDA", "common.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "platforms", "cuda.jl"))

# The script builds the libraries with a `_cuda` suffix (OPENCV_DLLVERSION); the product
# symbols stay those of OpenCV_jll so both JLLs expose the same API.
products = [
    [LibraryProduct("libopencv_$(m)_cuda", Symbol("libopencv_$(m)")) for m in opencv_modules];
    LibraryProduct("libopencv_julia", :libopencv_julia)
]

# CUDA 13.0 artifacts also match newer CUDA 13 toolkits.
platforms = AbstractPlatform[]
for p in CUDA.supported_platforms(; min_version=v"13", max_version=v"13.0.999"), v in julia_versions
    p = deepcopy(p)
    p["julia_version"] = string(v)
    push!(platforms, p)
end
platforms = expand_cxxstring_abis(platforms)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    if arch(platform) == "aarch64"
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", ["cuda_nvcc", "libnvvm"];
                                              version=CUDA.full_version(VersionNumber(platform["cuda"])),
                                              platform=x86_platform))
    end

    platform_dependencies = [
        dependencies;
        CUDA.required_dependencies(platform; static_sdk=true);
        Dependency("CUDNN_jll"; compat="9.28");
    ]

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, platform_dependencies;
                   julia_compat = libjulia_julia_compat(julia_versions),
                   preferred_gcc_version = v"10",
                   augment_platform_block = CUDA.augment,
                   lazy_artifacts = true,
                   dont_dlopen = true)
end
