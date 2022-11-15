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
${CC} -std=c99 -O2 -fPIC -shared -lnvToolsExt -o ${libdir}/libjulia_nvtx_callbacks.${dlext} callbacks.c 
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

cuda_builds = ["10.2", "11.0", "11.8"]
augment_platform_block = CUDA.augment

for build in cuda_builds, platform in platforms
    cuda_version = VersionNumber(build)
    augmented_platform = Platform(arch(platform), os(platform);
                                  cuda=CUDA.platform(cuda_version))
    should_build_platform(triplet(augmented_platform)) || continue

    build_tarballs(ARGS, name, version, sources, script, [augmented_platform], products, dependencies; julia_compat="1.6", augment_platform_block)
end
