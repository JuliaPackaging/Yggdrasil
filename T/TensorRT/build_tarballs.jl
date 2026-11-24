using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "TensorRT"
version = v"10.13.3"

cuda_versions = [
    v"11",
    v"12",
    v"13",
]

# Cf. https://docs.nvidia.com/deeplearning/tensorrt/10.x.x/getting-started/support-matrix.html
cudnn_versions = Dict(
    v"11" => Dict(
        Platform("x86_64", "linux") => v"8.9.7",
        Platform("x86_64", "windows") => v"8.9.7",
    ),
    v"12" => Dict(
        Platform("aarch64", "linux"; cuda_platform="jetson") => v"8.9.5", # Documentation says v"8.9.6", but v"8.9.5" is the most recent version available
        Platform("aarch64", "linux"; cuda_platform="sbsa") => v"8.9.7",
        Platform("x86_64", "linux") => v"8.9.7",
        Platform("x86_64", "windows") => v"8.9.7",
    ),
    # CUDNN_jll 8 has no CUDA 13 builds
    v"13" => Dict(
        Platform("aarch64", "linux") => v"9.13.0",
        Platform("x86_64", "linux") => v"9.13.0",
        Platform("x86_64", "windows") => v"9.13.0",
    ),
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
if [[ "$bb_full_target" == x86_64-linux-gnu*cuda+13* ]]; then
    # Otherwise the tarball exceeds GitHub's 2 GiB limit for release assets
    rm -v lib/libnvinfer_builder_resource_win.so.*
fi
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
        augmented_platform = only(expand_cxxstring_abis(augmented_platform; skip=!Sys.islinux))
        should_build_platform(triplet(augmented_platform)) || continue

        cudnn_version = cudnn_versions[cuda_version][platform]
        dependencies = [Dependency("CUDNN_jll", cudnn_version; compat="8, 9")]

        push!(builds, (; dependencies, platforms=[augmented_platform], sources))
    end
end

augment_platform_block = CUDA.augment

# xz ignores cgroup memory limits (until JuliaPackaging/BinaryBuilderBase.jl#510). Leave 4 GiB
# for the rest of the build, which used up to about 3.8 GiB alongside xz on CI.
ENV["XZ_DEFAULTS"] = "--memlimit-compress=$(max(Int(Sys.total_memory()) - (4 << 30), 1 << 30))"

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, build.dependencies;
                   augment_platform_block,
                   compression_format="xz",
                   dont_dlopen=true,
                   julia_compat="1.6")
end
