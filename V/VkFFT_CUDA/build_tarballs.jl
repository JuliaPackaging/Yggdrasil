using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "VkFFT_CUDA"
version = v"0.1.0"

# Must be the same libvkfft commit VkFFT_Metal and VkFFT_OpenCL build
# This is the commit the v0.1.0 tag points at.
const libvkfft_commit = "8d20a59e32bcacdc8ae09ba71ce4589719cd7257"

# VkFFT is a submodule of libvkfft and GitSource does not fetch submodules, so
# it is a source of its own. This is v1.3.4, the commit lib/VkFFT points at.
const vkfft_commit = "066a17c17068c0f11c9298d848c2976c71fad1c1"

sources = [
    GitSource("https://github.com/PaulVirally/libvkfft.git", libvkfft_commit),
    GitSource("https://github.com/DTolm/VkFFT.git", vkfft_commit),
]

script = raw"""
cd ${WORKSPACE}/srcdir
rm -rf libvkfft/lib/VkFFT
mv VkFFT libvkfft/lib/VkFFT
cd libvkfft

install_license LICENSE.md lib/VkFFT/LICENSE

export CUDA_HOME=${prefix}/cuda
export PATH=${PATH}:${CUDA_HOME}/bin

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCUDAToolkit_ROOT=${CUDA_HOME} \
    -DVKFFT_BACKEND=1 \
    -DVKFFT_MAX_FFT_DIMENSIONS=12 \
    -DVKFFT_WRAPPER_BUILD_TESTS=OFF \
    -DVKFFT_CUDA_TOOLKIT_ROOT_DIR=""
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = CUDA.supported_platforms(; min_version=v"12.0")
filter!(p -> arch(p) == "x86_64", platforms)

products = [
    LibraryProduct("libvkfft", :libvkfft),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # The auditor ignores libstdc++.so.6 but not libgcc_s.so.1, which every
    # GCC-built C++ shared library pulls in for the unwinder, so libgcc_s has to
    # come from a JLL. CUDA.required_dependencies supplies only CUDA_SDK_jll and
    # CUDA_Runtime_jll, hence the append.
    dependencies = [
        CUDA.required_dependencies(platform);
        Dependency(PackageSpec(; name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    ]

    build_tarballs(ARGS, name, version, sources, script, [platform], products,
                   dependencies;
                   julia_compat="1.10",
                   preferred_gcc_version=v"9",
                   augment_platform_block=CUDA.augment,
                   lazy_artifacts=true,
                   dont_dlopen=true)
end
