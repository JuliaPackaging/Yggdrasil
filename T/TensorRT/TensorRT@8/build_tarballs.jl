using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "TensorRT"
version = v"8.2.1"

cuda_versions = [
    v"10.2",
    v"11",
]

# Cf. https://docs.nvidia.com/deeplearning/tensorrt/archives/tensorrt-825/support-matrix/index.html
cudnn_version = v"8.2.1"

script = raw"""
mkdir -p $bindir $includedir $libdir
cd ${WORKSPACE}/srcdir

if [[ ${bb_full_target} == aarch64-linux-gnu*cuda+10.2 ]]; then
    apk add dpkg
    ls *.deb | xargs -Ideb_file dpkg-deb -x deb_file tmp
    install -Dv --mode=755 tmp/usr/src/tensorrt/bin/* $bindir
    install -Dv --mode=644 tmp/usr/include/$target/* $includedir
    install -Dv --mode=755 tmp/usr/lib/$target/*.so* $libdir
    install_license tmp/usr/share/doc/libnvinfer8/copyright
else
    cd TensorRT*
    mv bin/* ${bindir}
    mv include/* ${includedir}
    mv lib/*.${dlext}* ${libdir}

    if [[ ${target} == x86_64-w64-mingw32 ]]; then
        chmod +x ${bindir}/*.{dll,exe}
        install_license doc/TensorRT-SLA.pdf 
    else
        install_license doc/pdf/TensorRT-SLA.pdf 
    fi
fi
"""

lib_names = [
    "nvinfer",
    "nvinfer_plugin",
    "nvonnxparser",
    "nvparsers"
]

products = vcat(
    [LibraryProduct(["lib$lib_name", lib_name], Symbol("lib$lib_name"); dont_dlopen=true) for lib_name in lib_names],
    [ExecutableProduct("trtexec", :trtexec)]
)

builds = []
for cuda_version in cuda_versions
    include("build_cuda+$(cuda_version.major).jl")
    
    for (platform, sources) in platforms_and_sources
        augmented_platform = deepcopy(platform)
        augmented_platform["cuda"] = CUDA.platform(cuda_version)
        should_build_platform(triplet(augmented_platform)) || continue

        dependencies = [Dependency("CUDNN_jll", cudnn_version; compat="8.2")]

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
