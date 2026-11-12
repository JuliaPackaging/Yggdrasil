# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ONNXRuntime_CUDA"

include(joinpath(@__DIR__, "..", "common.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "C", "CUDA", "common.jl"))
include(joinpath(@__DIR__, "..", "..", "..", "platforms", "cuda.jl"))

# Cf. https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#requirements
# ONNX Runtime >= 1.25 requires CUDA >= 12.0 and cuDNN 9. Upstream builds with CUDA 12.8
# and 13.0; a CUDA 12.8 build also runs on newer CUDA 12 toolkits, likewise for 13.0.
platforms = [
    CUDA.supported_platforms(; min_version=v"12.8", max_version=v"12.8.999");
    CUDA.supported_platforms(; min_version=v"13.0", max_version=v"13.0.999");
]
# The CUDA 12 Jetson toolkit is too old for ONNX Runtime
filter!(p -> get(tags(p), "cuda_platform", "") != "jetson", platforms)
platforms = expand_cxxstring_abis(platforms)

append!(products, [
    LibraryProduct(["libonnxruntime_providers_cuda", "onnxruntime_providers_cuda"], :libonnxruntime_providers_cuda; dont_dlopen=true),
    LibraryProduct(["libonnxruntime_providers_shared", "onnxruntime_providers_shared"], :libonnxruntime_providers_shared),
])

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    platform_sources = AbstractSource[sources...]
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
        Dependency("CUDNN_jll"; compat="9");
        Dependency("Zlib_jll");
    ]

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, platform_dependencies;
                   augment_platform_block = CUDA.augment,
                   julia_compat = "1.6",
                   lazy_artifacts = true,
                   preferred_gcc_version)
end
