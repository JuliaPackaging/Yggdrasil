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

products = Product[
    FileProduct("include/mlx/mlx.h", :mlx_mlx_h),
    LibraryProduct("libmlx_cuda", :libmlx; dont_dlopen=true), # libmlx_cuda links libcuda, which comes with the NVIDIA driver; the JLL must load without one
]

preferred_gcc_version = v"12" # v12: GCC 11 rejects CCCL's `cuda/__iterator/transform_output_iterator.h` (`invalid use of non-static data member`)

# 12.6: the oldest toolkit tested by MLX; 12.8 and 12.9 add GPU archs
cuda_versions = ["12.6", "12.8", "12.9", "13.0"]

platforms = CUDA.supported_platforms()
filter!(p -> p["cuda"] in cuda_versions, platforms)
platforms = expand_cxxstring_abis(platforms)
CUDA.set_cuda_comparison_strategy!(platforms) # CUDNN_jll has artifacts for cuda+12.0 and cuda+13.0 only

non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)
    cuda_libraries = [
        RuntimeDependency(PackageSpec(name="CUDA_Compiler_jll"); compat="0.6.5"), # NVRTC, and the headers that it includes, for kernels compiled at run time
        Dependency(PackageSpec(name="CUDNN_jll"); compat="9.28"),
    ]

    # Machine code for sm_80 also runs on sm_86 and sm_89; MLX uses features specific to sm_90 and later (CUTLASS's
    # Hopper kernels, Blackwell's FP4 conversions)
    cuda_archs = CUDA.cuda_gpu_archs_cmake(filter(!in(("86", "89")), CUDA.cuda_gpu_archs(platform)); min_specific_arch="90")
    platform_script = "cuda_archs=\"$(cuda_archs)\"\n" * script

    platform_sources = BinaryBuilder.AbstractSource[sources...]
    cuda_major = VersionNumber(platform["cuda"]).major
    if arch(platform) == "aarch64"
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(platform_sources, get_sources("cuda", cuda_major >= 13 ? ["cuda_nvcc", "libnvvm"] : ["cuda_nvcc"];
                                              version=CUDA.full_version(VersionNumber(platform["cuda"])),
                                              platform=x86_platform))
    end

    build_tarballs(non_platform_ARGS, name, version, platform_sources, platform_script, [platform], products, [dependencies; cuda_deps; cuda_libraries];
                   lazy_artifacts=true,
                   julia_compat,
                   preferred_gcc_version,
                   augment_platform_block=CUDA.augment)
end
