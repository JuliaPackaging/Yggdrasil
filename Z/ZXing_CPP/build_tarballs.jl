# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "ZXing_CPP"
version = v"3.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zxing-cpp/zxing-cpp.git", "885baaf0840335153c1a487fa65f9c1388702c81"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zxing-cpp/
git submodule update --init

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DZXING_READERS=ON \
    -DZXING_WRITERS=ON \
    -DZXING_USE_BUNDLED_ZINT=ON \
    -DZXING_C_API=ON \
    -DZXING_EXPERIMENTAL_API=OFF
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

sources, script = require_macos_sdk("14.0", sources, script, deployment_target = "10.13")

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libZXing", :libZXing),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.10", preferred_gcc_version = v"11.1.0")
