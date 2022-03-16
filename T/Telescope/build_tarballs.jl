# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Telescope"
version = v"0.1.2"

# Collection of sources required to build this package
sources = [
    ArchiveSource("https://github.com/jhigginbotham64/Telescope/archive/refs/tags/v$(version).tar.gz",
              "025a24a5dfe4c4d5910ae0cad7664ec2c2fc21cce8ffaae56cc6b42300249de6"),
]

# Bash recipe for building across all platforms
script = raw"""
export CFLAGS="-I${prefix}/include"
export CXXFLAGS="-I${prefix}/include"
cd $WORKSPACE/srcdir/Telescope*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -S .. \
    -B .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("include/telescope.h", :telescope_h),
    LibraryProduct("libtelescope", :libtelescope),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("OpenGLMathematics_jll"),
    Dependency("SDL2_jll"),
    Dependency("SDL2_image_jll"),
    Dependency("SDL2_mixer_jll"),
    Dependency("SDL2_net_jll"),
    Dependency("SDL2_ttf_jll"),
    Dependency("Shaderc_jll"),
    HostBuildDependency("Vulkan_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8.1.0")
