using BinaryBuilder, Pkg
using BinaryBuilderBase
include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "VkFFTCUDALib"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PaulVirally/VkFFTCUDALib.git", "9c8cf2eae261b363e185e5043599ca2726f5aafd"),
]

script = raw"""
# Setup some necessary CUDA annoyingness
export CUDA_PATH="$prefix/cuda"
ln -s $prefix/cuda/lib $prefix/cuda/lib64

# Download and install VkFFTCUDALib
cd $WORKSPACE/srcdir/VkFFTCUDALib
git submodule update --init
mkdir build && cd build
cmake .. \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHS}" \
    -DCUDA_TOOLKIT_ROOT_DIR="${prefix}/cuda" \
    -DCMAKE_CUDA_COMPILER="${prefix}/cuda/bin/nvcc"
cmake --build . --parallel $nproc
cmake --install .

# We need a license file
install_license ../LICENSE
"""

# Build for 13.0 > CUDA >= 11.0
# NOTE: CUDA 13 is not yet supported because the CUDA_SDK_jlls are not available yet
#       (specifically for x86_64-linux-gnu-libgfortran5-cxx11-cuda+13.0)
platforms = CUDA.supported_platforms(min_version=v"11.0", max_version=v"12.9")
filter!(p -> arch(p)=="x86_64", platforms) # Cmake toolchain breaks on aarch64, so only x86_64 for now
filter!(p -> VersionNumber(p["cuda"]) != v"12.0", platforms) # CUDA 12.0 breaks for some reason

# The products that we will ensure are always built
products = [LibraryProduct("libVkFFTCUDA", :libVkFFTCUDA, dont_dlopen=true)]

# We need cmake >= 3.18 to build with CUDA
# CompilerSupportLibraries_jll is needed for gcc dynamic linking
dependencies = [
    HostBuildDependency(PackageSpec(; name="CMake_jll", version="3.28.1")),
    Dependency("CompilerSupportLibraries_jll")
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    # We need the static sdk
    cuda_deps = CUDA.required_dependencies(platform; static_sdk=true)

    # Build for all major archs supported by SDK
    # See https://en.wikipedia.org/wiki/CUDA
    if VersionNumber(platform["cuda"]) < v"11.8"
        cuda_archs = "50;60;70;80"
    else
        cuda_archs = "50;60;70;80;90"
    end
    arch_line = "export CUDA_ARCHS=\"$cuda_archs\"\n"
    platform_script = arch_line * script

    build_tarballs(ARGS, name, version, sources, platform_script, [platform],
                   products, [dependencies; cuda_deps];
                   preferred_gcc_version=v"11",
                   julia_compat="1.7",
                   augment_platform_block=CUDA.augment,
                   ignore_audit_errors = true
                   )
end
