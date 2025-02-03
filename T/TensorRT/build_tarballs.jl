using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "TensorRT"
version = v"10.5.0"

cuda_versions = [
    v"11",
    v"12",
]

# Cf. https://docs.nvidia.com/deeplearning/tensorrt/archives/tensorrt-1050/support-matrix/index.html
cudnn_versions = Dict(
    Platform("aarch64", "linux"; cuda_platform="jetson") => v"8.9.5", # Documentation says v"8.9.6", but v"8.9.5" is the most recent version available
    Platform("aarch64", "linux"; cuda_platform="sbsa") => v"8.9.7",
    Platform("x86_64", "linux") => v"8.9.7",
    Platform("x86_64", "windows") => v"8.9.7",
)

script = raw"""
mkdir -p $bindir $includedir $libdir

cd $WORKSPACE/srcdir

cd TensorRT*
if [[ "$target" == x86_64-w64-mingw32 ]]; then
    chmod +x bin/*.exe lib/*.dll
fi
mv -v bin/* $bindir
mv -v include/* $includedir
mv -v lib/*.${dlext}* $libdir
if [[ "$target" == *-linux-gnu ]]; then
    mv -v lib/stubs $libdir
fi
install_license doc/Acknowledgements.txt
"""

lib_names = [
    "nvinfer",
    "nvinfer_builder_resource",
    "nvinfer_dispatch",
    "nvinfer_lean",
    "nvinfer_plugin",
    "nvinfer_vc_plugin",
    "nvonnxparser",
]

products = vcat(
    [LibraryProduct(["lib$lib_name", "$(lib_name)_$(version.major)"], Symbol("lib$lib_name")) for lib_name in lib_names],
    [ExecutableProduct("trtexec", :trtexec)]
)

builds = []
for cuda_version in cuda_versions
    include("build_cuda+$(cuda_version.major).jl")

    for (platform, sources) in platforms_and_sources
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(cuda_version)
        should_build_platform(triplet(augmented_platform)) || continue

        cudnn_version = cudnn_versions[platform]
        dependencies = [Dependency("CUDNN_jll", cudnn_version; compat="8, 9")]

        push!(builds, (; dependencies, platforms=[augmented_platform], sources))
    end
end

augment_platform_block = CUDA.augment

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   julia_compat="1.6", augment_platform_block, dont_dlopen=true)
end
