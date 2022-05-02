# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Telescope"
version = v"0.2.0"

# Collection of sources required to build this package
sources = [
    GitSource("https://github.com/jhigginbotham64/Telescope.git",
              "0b88f367a1fe7905ca87b440b9d58ae1b0a43e8b"),
]

# Bash recipe for building across all platforms
script = raw"""
export CFLAGS="-I${includedir}"
export CXXFLAGS="-I${includedir}"
cd $WORKSPACE/srcdir/Telescope*
git submodule update --init --recursive
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
platforms = supported_platforms()
filter!(p -> (arch(p) != "armv6l") && !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    FileProduct("include/telescope.h", :telescope_h),
    LibraryProduct("libtelescope", :libtelescope),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Bullet_Physics_SDK_jll"),
    BuildDependency("OpenGLMathematics_jll"),
    Dependency("SDL2_jll"),
    Dependency("SDL2_image_jll"),
    Dependency("SDL2_mixer_jll"),
    Dependency("SDL2_net_jll"),
    Dependency("SDL2_ttf_jll"),
    Dependency("Shaderc_jll"),
    BuildDependency("Vulkan_Headers_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8.1.0")
