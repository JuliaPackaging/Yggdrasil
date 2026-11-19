# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, set_compare_strategy!, tags
using BinaryBuilderBase: get_addable_spec

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C", "CUDA", "common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "ONNXRuntime_CUDA"
version = v"1.32.0"

# Cf. https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#requirements
# Cf. https://onnxruntime.ai/docs/execution-providers/TensorRT-ExecutionProvider.html#requirements
# 12.0 for older drivers, 12.6 for JetPack 6, and the minors that add GPU architectures
cuda_versions = [
    v"12.0",
    v"12.6",
    v"12.8",
    v"12.9",
    v"13.0",
]

jetson_cuda_version = v"12.6"

cudnn_version = v"9.13.0"

tensorrt_version = v"10.4.0"

tensorrt_compat = "$(tensorrt_version.major).$(tensorrt_version.minor)"

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default sources
append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu_cuda12-$version.zip", "11b2ee6bc3c25b559503ec52eca14515d6e38dc4c532cc3017644b0f01d83a39"; unpack_target="onnxruntime-x86_64-w64-mingw32-cuda+12.8"),
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu_cuda13-$version.zip", "caa79b622b24861cfd8f0ad91d3e17eedad7dfc1bb9b23f6bdff70fa5a0f2351"; unpack_target="onnxruntime-x86_64-w64-mingw32-cuda+13.0"),
])

# Override the default platforms
is_jetson(p) = get(tags(p), "cuda_platform", "") == "jetson"
platforms = [p for v in cuda_versions
               for p in CUDA.supported_platforms(; min_version=v, max_version=VersionNumber(v.major, v.minor, 999))
               if is_jetson(p) == (v == jetson_cuda_version)]
append!(platforms, [Platform("x86_64", "windows"; cuda="12.8"), Platform("x86_64", "windows"; cuda="13.0")])

# CUDNN_jll and TensorRT_jll tag their CUDA 12 artifacts cuda+12.0, which BinaryBuilder only
# installs for an exact match. Match as `CUDA.augment` does at run time: same major, older minor.
# `should_build_platform` must then be given triplets, which match exactly.
function cuda_build_strategy(a::String, b::String, a_requested::Bool, b_requested::Bool)
    va, vb = tryparse(VersionNumber, a), tryparse(VersionNumber, b)
    (va === nothing || vb === nothing || a_requested == b_requested) && return a == b
    artifact, host = a_requested ? (vb, va) : (va, vb)
    artifact.major == host.major && Base.thisminor(artifact) <= Base.thisminor(host)
end
foreach(p -> set_compare_strategy!(p, "cuda", cuda_build_strategy), platforms)

# Override the default products
append!(products, [
    LibraryProduct(["libonnxruntime_providers_cuda", "onnxruntime_providers_cuda"], :libonnxruntime_providers_cuda; dont_dlopen=true),
    LibraryProduct(["libonnxruntime_providers_shared", "onnxruntime_providers_shared"], :libonnxruntime_providers_shared),
    LibraryProduct(["libonnxruntime_providers_tensorrt", "onnxruntime_providers_tensorrt"], :libonnxruntime_providers_tensorrt; dont_dlopen=true),
])

append!(dependencies, [
    Dependency("CUDNN_jll", cudnn_version; compat = "$(cudnn_version.major).$(cudnn_version.minor)"),
    Dependency("TensorRT_jll", tensorrt_version; compat = tensorrt_compat),
])

builds = []
for platform in platforms
    should_build_platform(triplet(platform)) || continue
    additional_sources = AbstractSource[]
    if Sys.islinux(platform) && arch(platform) == "aarch64"
        cuda_version = VersionNumber(platform["cuda"])
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        # libnvvm is part of cuda_nvcc before CUDA 13
        components = cuda_version >= v"13" ? ["cuda_nvcc", "libnvvm"] : ["cuda_nvcc"]
        append!(additional_sources, get_sources("cuda", components;
                                                version=CUDA.full_version(cuda_version),
                                                platform=x86_platform))
    end
    additional_deps = CUDA.required_dependencies(platform, static_sdk = true)
    if Sys.iswindows(platform)
        filter!(dep -> !isa(dep, BuildDependency), additional_deps)
    end
    cuda_archs = CUDA.cuda_gpu_archs_cmake(platform)
    push!(builds, (; platforms=[platform], sources=[sources; additional_sources],
                     script="CUDA_ARCHS=\"$cuda_archs\"\n" * script, dependencies=[dependencies; additional_deps]))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, build.script,
                   build.platforms, products, build.dependencies;
                   augment_platform_block = CUDA.augment,
                   dont_dlopen = true,
                   julia_compat = "1.10",
                   lazy_artifacts = true,
                   lock_microarchitecture = false, # MLAS selects its -march kernels at run time
                   preferred_gcc_version)
end

# trigger 2
