using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "VkFFT_Metal"
version = v"0.1.0"

# Must be the same libvkfft commit VkFFT_CUDA and VkFFT_OpenCL build.
const libvkfft_commit = "c608fa9e2fe6a65ba8e51b46cc3f4f570cf163ab"

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

# Nothing to point at Metal here. The backend 5 branch of libvkfft's
# CMakeLists takes metal-cpp from the vendored VkFFT checkout and links
# Foundation, QuartzCore and Metal itself. It also refuses to configure
# unless CMake sets APPLE, which the Darwin toolchain file does.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DVKFFT_BACKEND=5 \
    -DVKFFT_MAX_FFT_DIMENSIONS=12 \
    -DVKFFT_WRAPPER_BUILD_TESTS=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# metal-cpp includes <IOSurface/IOSurfaceRef.h>, and the 10.12 SDK the sandbox
# defaults to on x86_64 does not ship that header, so the build cannot work
# there without a newer SDK. 11.1 is the oldest one that has it, and it is
# already the aarch64 default, but 14.0 is what the other recipes in the tree
# use. The deployment target is low because metal-cpp resolves every selector
# through the Objective-C runtime, so none of it needs a recent OS to load.
sources, script = require_macos_sdk("14.0", sources, script; deployment_target="10.15")

# Backend 5 is macOS only. An explicit pair says so at the platform list rather
# than leaving it to a FATAL_ERROR inside CMake.
platforms = [Platform("x86_64", "macos"), Platform("aarch64", "macos")]

products = [
    LibraryProduct("libvkfft", :libvkfft),
]
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat="1.10", preferred_gcc_version=v"10")
