# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "C", "CUDA", "common.jl"))

name = "MLX_CUDA"
version = v"0.32.4"

include(joinpath(@__DIR__, "..", "common.jl"))

# libmlx links the CUDA driver, so the JLL must import without one
products = Product[
    FileProduct("include/mlx/mlx.h", :mlx_mlx_h),
    LibraryProduct(["libmlx", "mlx"], :libmlx; dont_dlopen=true),
]

preferred_gcc_version = v"12" # v12: GCC 11 rejects CCCL's `cuda/__iterator/transform_output_iterator.h` (`invalid use of non-static data member`)

# An artifact is selected for drivers supporting its CUDA version or a later minor one, so build for the oldest
# toolkit tested by MLX (12.6), and for those adding GPU archs (12.8, 12.9); MLX does not support CUDA 13.1, so
# CUDA 13.x drivers use the 13.0 artifact
cuda_versions = ["12.6", "12.8", "12.9", "13.0"]

platforms = CUDA.supported_platforms()
filter!(p -> p["cuda"] in cuda_versions, platforms)

# Build for all supported CUDA toolkits
for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)
    cuda_libraries = [
        RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.6.5"), # NVRTC, and the headers that it includes, for kernels compiled at run time
        RuntimeDependency(PackageSpec(name="CUDNN_jll"); compat="9.28"),
    ]

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    cuda_major = VersionNumber(platform["cuda"]).major
    if arch(platform) == "aarch64"
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", cuda_major >= 13 ? ["cuda_nvcc", "libnvvm"] : ["cuda_nvcc"];
                                              version=CUDA.full_version(VersionNumber(platform["cuda"])),
                                              platform=x86_platform))
    end

    # Build against the cuDNN redist, as CUDNN_jll has an artifact per CUDA major, which does not match the CUDA
    # minor of the platform when building
    source_platform = deepcopy(platform)
    if cuda_major == 12 && arch(platform) == "aarch64"
        source_platform["cuda_platform"] = "sbsa" # the redist has no Jetson archive for CUDA 12, as for CUDNN_jll
    end
    append!(platform_sources, get_sources("cudnn", ["cudnn"]; version=v"9.28.0", platform=source_platform,
                                          variant="cuda$(cuda_major)"))

    build_tarballs(ARGS, name, version, platform_sources, script, [platform], products, [dependencies; cuda_deps; cuda_libraries];
                   lazy_artifacts=true,
                   julia_compat,
                   preferred_gcc_version,
                   augment_platform_block=CUDA.augment,
                   dont_dlopen=true)
end
