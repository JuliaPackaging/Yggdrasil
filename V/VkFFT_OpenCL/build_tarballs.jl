using BinaryBuilder, Pkg

name = "VkFFT_OpenCL"
version = v"0.1.0"

# Must be the same libvkfft commit VkFFT_CUDA and VkFFT_Metal build
# This is the commit the v0.1.0 tag points at.
const libvkfft_commit = "8d20a59e32bcacdc8ae09ba71ce4589719cd7257"

sources = [
    GitSource("https://github.com/PaulVirally/libvkfft.git", libvkfft_commit),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libvkfft
git submodule update --init # VkFFT itself (v1.3.4) is a submodule in lib/VkFFT

install_license LICENSE.md lib/VkFFT/LICENSE

# FindOpenCL locates the ICD loader from OpenCL_jll and the headers from
# OpenCL_Headers_jll under ${prefix}. On macOS the SDK's OpenCL.framework would
# otherwise be found first, and libvkfft has to call the same loader OpenCL.jl
# does, so frameworks are excluded from the search.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_FIND_FRAMEWORK=NEVER \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DVKFFT_BACKEND=3 \
    -DVKFFT_MAX_FFT_DIMENSIONS=12 \
    -DVKFFT_WRAPPER_BUILD_TESTS=OFF \
    -DVKFFT_OPENCL_FORCE_ICD_LOADER=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libvkfft", :libvkfft),
]

dependencies = [
    BuildDependency(PackageSpec(; name="OpenCL_Headers_jll", version="2025.06.13")),
    Dependency("OpenCL_jll"),
    Dependency(PackageSpec(; name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat="1.10", preferred_gcc_version=v"9")
