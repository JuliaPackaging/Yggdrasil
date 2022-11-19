using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch, os

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "JuliaNVTXCallbacks"
version = v"0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/simonbyrne/NVTX.jl",
              "079ab5516320242353cb168b115b0200a14a6cf8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/NVTX.jl/deps
mkdir -p ${libdir}
CUDA_PATH="${prefix}/cuda"
ls ${CUDA_PATH}/include
${CC} -std=c99 -O2 -fPIC -shared -I${CUDA-PATH}/include -lnvToolsExt -o ${libdir}/libjulia_nvtx_callbacks.${dlext} callbacks.c 
install_license /usr/share/licenses/MIT
"""

# The products that we will ensure are always built
products = [
    LibraryProduct("libjulia_nvtx_callbacks", :libjulia_nvtx_callbacks),
]

dependencies = [Dependency("CUDA_Runtime_jll")]

# CUDA platforms
platforms = [Platform("x86_64", "linux"),
             Platform("powerpc64le", "linux"),
             Platform("aarch64", "linux"),
             Platform("x86_64", "windows")]

cuda_versions = [v"10.2", v"11.0", v"11.8"]

cuda_full_versions = Dict(
    v"10.2" => v"10.2.89",
    v"11.0" => v"11.0.3",
    v"11.4" => v"11.4.2",
    v"11.8" => v"11.8"
)


augment_platform_block = CUDA.augment

for cuda_version in cuda_versions, platform in platforms
    # not all platforms have all versions of CUDA_Runtime_jll
    if cuda_version < v"11.0" && platform == Platform("powerpc64le", "linux")
        continue
    end
    if cuda_version == v"11.0" && platform == Platform("aarch64", "linux")
        cuda_version = v"11.4"
    end

    
    augmented_platform = Platform(arch(platform), os(platform);
                                  cuda=CUDA.platform(cuda_version))
    should_build_platform(triplet(augmented_platform)) || continue

    
    cuda_deps = [
        BuildDependency(PackageSpec(name="CUDA_full_jll",
                                    version=cuda_full_versions[cuda_version])),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]

    build_tarballs(ARGS, name, version, sources, script, [augmented_platform], products, [dependencies; cuda_deps];
                   lazy_artifacts=true, julia_compat="1.6", augment_platform_block)
end
