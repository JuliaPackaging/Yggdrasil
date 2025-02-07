using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

include("../common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "CUDNN"
version = v"8.9.5"

script = raw"""
mkdir -p ${libdir} ${prefix}/include

cd ${WORKSPACE}/srcdir
if [[ ${target} == *-linux-gnu ]]; then
    cd cudnn*
    find .

    install_license LICENSE

    mv lib/libcudnn*.so* ${libdir}
    mv include/* ${prefix}/include
elif [[ ${target} == x86_64-w64-mingw32 ]]; then
    cd cudnn*
    find .

    install_license LICENSE

    mv bin/cudnn*64_*.dll ${libdir}
    mv include/* ${prefix}/include

    mv ../dll_x64/zlibwapi.dll ${libdir}

    # fixup
    chmod +x ${libdir}/*.dll
fi
"""

augment_platform_block = CUDA.augment

products = [
    LibraryProduct(["libcudnn_ops_infer", "cudnn_ops_infer64_$(version.major)"], :libcudnn_ops_infer64),
    LibraryProduct(["libcudnn_ops_train", "cudnn_ops_train64_$(version.major)"], :libcudnn_ops_train64),
    LibraryProduct(["libcudnn_cnn_infer", "cudnn_cnn_infer64_$(version.major)"], :libcudnn_cnn_infer64),
    LibraryProduct(["libcudnn_cnn_train", "cudnn_cnn_train64_$(version.major)"], :libcudnn_cnn_train64),
    LibraryProduct(["libcudnn_adv_infer", "cudnn_adv_infer64_$(version.major)"], :libcudnn_adv_infer64),
    LibraryProduct(["libcudnn_adv_train", "cudnn_adv_train64_$(version.major)"], :libcudnn_adv_train64),

    # shim layer
    LibraryProduct(["libcudnn", "cudnn64_$(version.major)"], :libcudnn),
]

dependencies = [RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll"))]

platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"; cuda_platform="jetson"),
             Platform("aarch64", "linux"; cuda_platform="sbsa"),
             Platform("x86_64", "windows")]

builds = []
for cuda_version in [v"11", v"12"], platform in platforms
    augmented_platform = deepcopy(platform)
    augmented_platform["cuda"] = CUDA.platform(cuda_version)
    should_build_platform(triplet(augmented_platform)) || continue

    if arch(platform) == "aarch64"
        # Tegra binaries are only provided for CUDA 12.x
        if platform["cuda_platform"] == "jetson" && cuda_version == v"11"
            continue
        end
    end

    sources = get_sources("cudnn", ["cudnn"]; version, platform,
                           variant="cuda$(cuda_version.major)")

    if platform == Platform("x86_64", "windows")
        push!(sources,
            ArchiveSource("http://www.winimage.com/zLibDll/zlib123dllx64.zip",
                            "fd324c6923aa4f45a60413665e0b68bb34a7779d0861849e02d2711ff8efb9a4"))
    end

    push!(builds, (; platforms=[augmented_platform], sources))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, dependencies;
                   julia_compat="1.6", augment_platform_block, dont_dlopen=true)
end

