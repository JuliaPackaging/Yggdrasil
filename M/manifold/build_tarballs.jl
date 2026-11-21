# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "manifold"
version = v"3.5.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/elalish/manifold.git", "32271a1a999ce721ffaf5ab10e9746ceeb696547";
              tag="v$(version)"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/manifold
# MANIFOLD_DOWNLOADS=OFF: fail if Clipper2_jll is not found, rather than download Clipper2.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DMANIFOLD_DOWNLOADS=OFF \
    -DMANIFOLD_TEST=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmanifoldc", :libmanifoldc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Clipper2_jll"; compat="2.0.1"),
]

# `std::optional::value()` needs macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

# Build the tarballs, and possibly a `build.jl` as well.
# GCC 10 because Clipper2_jll is built with it.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
