# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "ONNXRuntime_CUDA"
version = v"1.10.0"

# Cf. https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html#requirements
# Cf. https://onnxruntime.ai/docs/execution-providers/TensorRT-ExecutionProvider.html#requirements
cuda_versions = [
    v"10.2",
    v"11.3", # Using 11.3, and not 11.4, to be compatible with CUDNN v8.2.4, and with TensorRT (JLL) v8.0.1 (where the latter includes aarch64 support).
]
cudnn_version = v"8.2.4"
tensorrt_version = v"8.0.1"

cudnn_compat = string(cudnn_version.major)
tensorrt_compat = string(tensorrt_version.major)

include(joinpath(@__DIR__, "..", "common.jl"))

# Override the default sources
append!(sources, [
    ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu-$version.zip", "0da11b8d953fad4ec75f87bb894f72dea511a3940cff2f4dad37451586d1ebbc"; unpack_target="onnxruntime-x86_64-w64-mingw32-cuda"),
    # aarch64-linux-gnu binaries for NVIDIA Jetson from NVIDIA-managed Jetson Zoo: https://elinux.org/Jetson_Zoo#ONNX_Runtime
    FileSource("https://nvidia.box.com/shared/static/jy7nqva7l88mq9i8bw3g3sklzf4kccn2.whl", "a608b7a4a4fc6ad5c90d6005edbfe0851847b991b08aafff4549bbbbdb938bf6"; filename = "onnxruntime-aarch64-linux-gnu-cuda.whl"),
])

# Override the default platforms
platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11")
filter!(p -> !(arch(p) == "x86_64" && Sys.islinux(p) && p["cuda"] == "10.2"), platforms) # Fails with: nvcc error   : 'ptxas' died due to signal 11 (Invalid memory reference)
push!(platforms, Platform("x86_64", "Linux"; cuda = "11.3"))
push!(platforms, Platform("x86_64", "Windows"; cuda = "11.3"))
platforms = expand_cxxstring_abis(platforms; skip=!Sys.islinux)

# Override the default products
append!(products, [
    LibraryProduct(["libonnxruntime_providers_cuda", "onnxruntime_providers_cuda"], :libonnxruntime_providers_cuda; dont_dlopen=true),
    LibraryProduct(["libonnxruntime_providers_shared", "onnxruntime_providers_shared"], :libonnxruntime_providers_shared),
    LibraryProduct(["libonnxruntime_providers_tensorrt", "onnxruntime_providers_tensorrt"], :libonnxruntime_providers_tensorrt; dont_dlopen=true),
])

append!(dependencies, [
    Dependency(get_addable_spec("CUDNN_jll", v"8.2.4+0"); compat = cudnn_compat), # Using v"8.2.4+0" to get support for cuda = "11.3"
    Dependency("TensorRT_jll", tensorrt_version; compat = tensorrt_compat),
    Dependency("Zlib_jll"),
])

builds = []
for platform in platforms
    should_build_platform(platform) || continue
    additional_deps = BinaryBuilder.AbstractDependency[]
    if platform["cuda"] == "11.3"
        additional_deps = BinaryBuilder.AbstractDependency[
            BuildDependency(PackageSpec("CUDA_full_jll", v"11.3.1")),
            Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using v"0.7.0" to get support for cuda = "11.3" - using Dependency rather than RuntimeDependency to be sure to pass audit
        ]
    else
        additional_deps = CUDA.required_dependencies(platform, static_sdk = true)
    end
    push!(builds, (; platforms=[platform], dependencies=[dependencies; additional_deps]))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
                   augment_platform_block = CUDA.augment,
                   julia_compat = "1.6",
                   lazy_artifacts = true,
                   preferred_gcc_version = v"8")
end

# trigger 1
