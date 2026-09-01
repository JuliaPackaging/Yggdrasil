using BinaryBuilder, Pkg

name = "VkFFT_OpenCL"
version = v"0.1.0"

# Must be the same libvkfft commit VkFFT_CUDA and VkFFT_Metal build
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

opencl_library=${libdir}/libOpenCL.${dlext}
if [[ "${target}" == *-mingw* ]]; then
    # TODO: unverified against a real Windows build of OpenCL_jll.
    opencl_library=${prefix}/lib/libOpenCL.dll.a
fi

# TODO: VKFFT_OPENCL_FORCE_ICD_LOADER does not exist in libvkfft yet. Its CMake
# takes the `-framework OpenCL` branch unconditionally on APPLE.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DVKFFT_BACKEND=3 \
    -DVKFFT_MAX_FFT_DIMENSIONS=12 \
    -DVKFFT_WRAPPER_BUILD_TESTS=OFF \
    -DVKFFT_OPENCL_FORCE_ICD_LOADER=ON \
    -DOpenCL_LIBRARY=${opencl_library} \
    -DOpenCL_INCLUDE_DIR=${includedir}
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
