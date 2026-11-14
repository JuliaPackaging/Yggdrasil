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

# nvcc isn't a cross compiler, so on Windows we repackage upstream's MSVC builds (cuDNN 9;
# `cuda12` is built with CUDA 12.8). The common script expects them in this directory.
windows_sources = Dict(
    "12.8" => ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu_cuda12-$version.zip",
                            "5cbf65edc93dc7bb3296249b1b6e1b2228e575902af64d6163d0da2103cef9d5";
                            unpack_target="onnxruntime-x86_64-w64-mingw32-cuda"),
    "13.0" => ArchiveSource("https://github.com/microsoft/onnxruntime/releases/download/v$version/onnxruntime-win-x64-gpu_cuda13-$version.zip",
                            "6c64508de9c04f9d938297287e9d81fa47a2fbbb30cc04e6fac0db88f6cb68c1";
                            unpack_target="onnxruntime-x86_64-w64-mingw32-cuda"),
)
append!(platforms, [Platform("x86_64", "windows"; cuda) for cuda in sort(collect(keys(windows_sources)))])

# The upstream Windows packages include the TensorRT EP, which needs TensorRT 10 DLLs that
# we don't provide (TensorRT_jll is CUDA 12 only); drop it.
script = raw"""
rm -f $WORKSPACE/srcdir/onnxruntime-*-cuda/onnxruntime-*/lib/onnxruntime_providers_tensorrt.*
""" * script

append!(products, [
    LibraryProduct(["libonnxruntime_providers_cuda", "onnxruntime_providers_cuda"], :libonnxruntime_providers_cuda; dont_dlopen=true),
    LibraryProduct(["libonnxruntime_providers_shared", "onnxruntime_providers_shared"], :libonnxruntime_providers_shared),
])

# `build_tarballs` would otherwise take the platforms from ARGS: we select them ourselves with
# `should_build_platform`, and pass `--register` only to the last build.
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)
build_platforms = filter(p -> should_build_platform(triplet(p)), platforms)

for (i, platform) in enumerate(build_platforms)

    platform_sources = if Sys.iswindows(platform)
        AbstractSource[windows_sources[platform["cuda"]]]
    else
        AbstractSource[sources...]
    end
    if Sys.islinux(platform) && arch(platform) == "aarch64"
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        cuda_version = VersionNumber(platform["cuda"])
        # libnvvm is part of cuda_nvcc before CUDA 13
        components = cuda_version >= v"13" ? ["cuda_nvcc", "libnvvm"] : ["cuda_nvcc"]
        append!(platform_sources, get_sources("cuda", components;
                                              version=CUDA.full_version(cuda_version),
                                              platform=x86_platform))
    end

    if Sys.islinux(platform) && VersionNumber(platform["cuda"]) < v"13"
        # CUDNN_jll's CUDA 12 artifacts are tagged cuda+12.0, which BinaryBuilder does not
        # install for cuda+12.8 (only the run-time augmentation treats them as compatible).
        # Build against the matching redist archive; CUDNN_jll provides cuDNN at run time.
        append!(platform_sources, get_sources("cudnn", ["cudnn"]; version=v"9.28.0",
                                              platform, variant="cuda12"))
    end

    cuda_dependencies = CUDA.required_dependencies(platform; static_sdk=true)
    if Sys.iswindows(platform)
        # repackaging upstream's build only needs the run-time dependencies, not the SDK
        filter!(dep -> !isa(dep, BuildDependency), cuda_dependencies)
    end
    platform_dependencies = [
        dependencies;
        cuda_dependencies;
        # cuDNN is dlopen()'ed at run time (cudnn_frontend dynamic loading), so it isn't a
        # NEEDED entry, but it must be loadable: CUDNN_jll provides it. Pin the build version,
        # as the resolver otherwise picks CUDNN_jll 9.0, which has no CUDA 13 artifacts.
        Dependency("CUDNN_jll", v"9.28.0"; compat="9");
    ]

    build_tarballs(i == lastindex(build_platforms) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, platform_sources, script, [platform], products, platform_dependencies;
                   augment_platform_block = CUDA.augment,
                   julia_compat = "1.10", # libstdc++ with GLIBCXX_3.4.30 (GCC 12)
                   lazy_artifacts = true,
                   # MLAS compiles individual kernels with `-march=armv8.2-a+bf16` etc. and selects
                   # them at runtime, so the compiler wrappers must not reject `-march`.
                   lock_microarchitecture = false,
                   preferred_gcc_version)
end
